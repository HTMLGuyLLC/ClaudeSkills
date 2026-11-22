#!/usr/bin/env node
// Turns test-runner reports into short summaries and before/after checks.
// Reads Jest-format JSON (Jest --json, Vitest --reporter=json) and JUnit XML
// (pytest, Go via gotestsum, PHPUnit, most other runners). No dependencies.
//
//   report.mjs summary  <report> [--top n]
//   report.mjs diff     <before-report> <after-report> [--allow <file>]
//   report.mjs coverage <before-summary.json> <after-summary.json>
//
// diff and coverage exit 1 when protection was lost, so a script can gate on them.

import { readFileSync } from 'node:fs'
import { relative, isAbsolute } from 'node:path'

const [cmd, ...rest] = process.argv.slice(2)
const flags = {}
const args = []
for (let i = 0; i < rest.length; i++) {
  if (rest[i].startsWith('--')) flags[rest[i].slice(2)] = rest[++i]
  else args.push(rest[i])
}

function die(msg) {
  console.error(`report.mjs: ${msg}`)
  process.exit(2)
}

function read(file) {
  try {
    return readFileSync(file, 'utf8')
  } catch (e) {
    die(`can't read ${file}: ${e.code || e.message}`)
  }
}

function rel(file) {
  if (!file) return '(unknown file)'
  return isAbsolute(file) ? relative(process.cwd(), file) : file
}

const unescape = (s) =>
  s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&amp;/g, '&')

function attr(tag, name) {
  const m = tag.match(new RegExp(`\\s${name}="([^"]*)"`))
  return m ? unescape(m[1]) : undefined
}

// Normalized shape: { files: [{ file, ms, tests: [{ id, name, status, ms }] }] }
function load(file) {
  const text = read(file).trim()
  if (text.startsWith('{')) return fromJest(JSON.parse(text), file)
  if (text.startsWith('<')) return fromJunit(text)
  die(`${file} is neither Jest-format JSON nor JUnit XML`)
}

function fromJest(json, file) {
  if (!Array.isArray(json.testResults)) die(`${file} has no testResults array`)
  return {
    files: json.testResults.map((r) => {
      const name = rel(r.name || r.testFilePath)
      const tests = (r.assertionResults || r.testResults || []).map((t) => {
        const title = t.fullName || [...(t.ancestorTitles || []), t.title].join(' ')
        return { id: `${name} > ${title}`, name: title, status: normStatus(t.status), ms: t.duration || 0 }
      })
      const timed = typeof r.startTime === 'number' && typeof r.endTime === 'number' && r.endTime >= r.startTime
      const ms = timed ? r.endTime - r.startTime : tests.reduce((a, t) => a + t.ms, 0)
      // A file that failed to load has no tests but still counts as broken.
      if (!tests.length && r.status === 'failed') tests.push({ id: `${name} > (file failed to load)`, name: '(file failed to load)', status: 'failed', ms: 0 })
      return { file: name, ms, tests }
    }),
  }
}

function fromJunit(xml) {
  const byFile = new Map()
  const cases = xml.matchAll(/<testcase\b([^>]*?)(\/>|>([\s\S]*?)<\/testcase>)/g)
  for (const [, attrs, , body = ''] of cases) {
    const tag = ` ${attrs}`
    const file = rel(attr(tag, 'file') || attr(tag, 'classname') || '(unknown file)')
    const name = attr(tag, 'name') || '(unnamed)'
    const status = /<(failure|error)\b/.test(body) ? 'failed' : /<skipped\b/.test(body) ? 'skipped' : 'passed'
    const ms = Math.round(parseFloat(attr(tag, 'time') || '0') * 1000)
    if (!byFile.has(file)) byFile.set(file, { file, ms: 0, tests: [] })
    const entry = byFile.get(file)
    entry.ms += ms
    entry.tests.push({ id: `${file} > ${name}`, name, status, ms })
  }
  return { files: [...byFile.values()] }
}

function normStatus(s) {
  if (s === 'passed' || s === 'pass') return 'passed'
  if (s === 'failed' || s === 'fail') return 'failed'
  return 'skipped' // pending, todo, skipped, disabled
}

const secs = (ms) => `${(ms / 1000).toFixed(1)}s`
const allTests = (r) => r.files.flatMap((f) => f.tests)

function counts(r) {
  const c = { passed: 0, failed: 0, skipped: 0 }
  for (const t of allTests(r)) c[t.status]++
  return c
}

function summary(file) {
  const top = Number(flags.top || 15)
  const r = load(file)
  const tests = allTests(r)
  const c = counts(r)
  const fileMs = r.files.reduce((a, f) => a + f.ms, 0)
  const testMs = tests.reduce((a, t) => a + t.ms, 0)
  console.log(`files: ${r.files.length}`)
  console.log(`tests: ${tests.length} (passed ${c.passed}, failed ${c.failed}, skipped ${c.skipped})`)
  console.log(`file_time_total: ${secs(fileMs)}`)
  console.log(`test_body_time_total: ${secs(testMs)}`)
  // Per-file time the test bodies don't explain is load, setup and environment cost.
  console.log(`overhead_time_total: ${secs(Math.max(0, fileMs - testMs))}`)

  console.log(`\nslowest_files (total / in tests / tests):`)
  for (const f of [...r.files].sort((a, b) => b.ms - a.ms).slice(0, top)) {
    const inTests = f.tests.reduce((a, t) => a + t.ms, 0)
    console.log(`  ${secs(f.ms)} / ${secs(inTests)} / ${f.tests.length}  ${f.file}`)
  }

  console.log(`\nslowest_tests:`)
  for (const t of [...tests].sort((a, b) => b.ms - a.ms).slice(0, top)) console.log(`  ${secs(t.ms)}  ${t.id}`)

  const small = r.files.filter((f) => f.tests.length <= 2).length
  console.log(`\nfiles_with_1_or_2_tests: ${small}`)

  const titles = new Map()
  for (const f of r.files) for (const t of f.tests) titles.set(t.name, (titles.get(t.name) || new Set()).add(f.file))
  const repeated = [...titles].filter(([, files]) => files.size > 1).sort((a, b) => b[1].size - a[1].size)
  console.log(`same_title_in_several_files: ${repeated.length}`)
  for (const [name, files] of repeated.slice(0, top)) console.log(`  ${files.size}x  ${name}`)
}

function diff(beforeFile, afterFile) {
  const before = load(beforeFile)
  const after = load(afterFile)
  // Lines in the allow file are test ids or names deliberately replaced, each
  // followed by " => " and what covers it now. Anything else missing fails.
  const allowed = new Map()
  if (flags.allow) {
    for (const line of read(flags.allow).split('\n')) {
      const [id, why] = line.split(' => ')
      if (id.trim() && why && why.trim()) allowed.set(id.trim(), why.trim())
    }
  }
  // Exact matches first, so a moved test never claims one that stayed put.
  const afterById = new Map(allTests(after).map((t) => [t.id, t]))
  const matched = new Map()
  for (const t of allTests(before)) if (afterById.has(t.id)) matched.set(t, afterById.get(t.id))
  const claimed = new Set(matched.values())
  const unclaimedByName = new Map()
  for (const t of allTests(after)) {
    if (!claimed.has(t)) unclaimedByName.set(t.name, [...(unclaimedByName.get(t.name) || []), t])
  }

  const missing = [], moved = [], replaced = [], worse = []
  for (const t of allTests(before)) {
    let now = matched.get(t)
    if (!now) {
      const sameName = unclaimedByName.get(t.name)
      if (sameName && sameName.length) {
        now = sameName.shift()
        moved.push(`${t.id}  ->  ${now.id}`)
      }
    }
    if (!now) {
      const why = allowed.get(t.id) || allowed.get(t.name)
      if (why) replaced.push(`${t.id}  =>  ${why}`)
      else missing.push(t.id)
      continue
    }
    if (t.status === 'passed' && now.status !== 'passed') worse.push(`${now.id} (${now.status})`)
  }

  const b = counts(before), a = counts(after)
  const bMs = before.files.reduce((s, f) => s + f.ms, 0)
  const aMs = after.files.reduce((s, f) => s + f.ms, 0)
  console.log(`files: ${before.files.length} -> ${after.files.length}`)
  console.log(`tests: ${allTests(before).length} -> ${allTests(after).length}`)
  console.log(`passed: ${b.passed} -> ${a.passed}, failed: ${b.failed} -> ${a.failed}, skipped: ${b.skipped} -> ${a.skipped}`)
  console.log(`file_time_total: ${secs(bMs)} -> ${secs(aMs)}`)
  const list = (label, items) => {
    console.log(`${label}: ${items.length}`)
    for (const i of items) console.log(`  ${i}`)
  }
  list('moved', moved)
  list('replaced', replaced)
  list('missing', missing)
  list('no_longer_passing', worse)
  const ok = !missing.length && !worse.length
  console.log(`protection: ${ok ? 'kept' : 'LOST'}`)
  process.exit(ok ? 0 : 1)
}

function coverage(beforeFile, afterFile) {
  const parse = (f) => {
    const j = JSON.parse(read(f))
    if (!j.total) die(`${f} isn't an istanbul json-summary (no "total")`)
    const out = new Map()
    for (const [k, v] of Object.entries(j)) out.set(k === 'total' ? 'total' : rel(k), v)
    return out
  }
  const before = parse(beforeFile)
  const after = parse(afterFile)
  const kinds = ['lines', 'branches', 'functions', 'statements']
  const drops = []
  for (const [file, b] of before) {
    const a = after.get(file)
    if (!a) {
      if (b.lines && b.lines.covered > 0) drops.push(`${file}: no longer in the report`)
      continue
    }
    for (const k of kinds) {
      if (!b[k] || !a[k]) continue
      // Covered count catches lost coverage even when the total moved too.
      if (a[k].covered < b[k].covered) drops.push(`${file}: ${k} covered ${b[k].covered} -> ${a[k].covered}`)
      else if (a[k].pct < b[k].pct && a[k].total === b[k].total) drops.push(`${file}: ${k} ${b[k].pct}% -> ${a[k].pct}%`)
    }
  }
  for (const k of kinds) {
    const b = before.get('total')[k], a = after.get('total')[k]
    if (b && a) console.log(`total_${k}: ${b.pct}% (${b.covered}/${b.total}) -> ${a.pct}% (${a.covered}/${a.total})`)
  }
  console.log(`coverage_drops: ${drops.length}`)
  for (const d of drops) console.log(`  ${d}`)
  console.log(`protection: ${drops.length ? 'LOST' : 'kept'}`)
  process.exit(drops.length ? 1 : 0)
}

if (cmd === 'summary' && args.length === 1) summary(args[0])
else if (cmd === 'diff' && args.length === 2) diff(args[0], args[1])
else if (cmd === 'coverage' && args.length === 2) coverage(args[0], args[1])
else die('usage: report.mjs summary <report> [--top n] | diff <before> <after> [--allow <file>] | coverage <before> <after>')
