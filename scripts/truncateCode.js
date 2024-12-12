const fs = require("fs")
const { argv } = require("process")

const NOP = 0x4e71
const HUNK_HEADER = 0x3f3
const HUNK_END = 0x3f2

const inFile = argv[2]
if (!inFile) {
  console.error('no input file')
  process.exit(1)
}

const outFile = argv[3]
if (!outFile) {
  console.error('no output file')
  process.exit(1)
}

const buf = fs.readFileSync(inFile)

let offset = 0
const nextLong = () => buf.readUInt32BE((offset++) * 4)

const hunkType = nextLong()
if (hunkType !== HUNK_HEADER) {
  console.error('Expected hunk header type: ' + hunkType.toString(16))
  process.exit()
}

while (nextLong() !== 0) { } // skip strings

const tableSize = nextLong()
const firstHunk = nextLong()
const lastHunk = nextLong()

if (tableSize !== 1 || firstHunk !== 0 || lastHunk !== 0) {
  console.error('Expected exactly 1 hunk')
  process.exit(1)
}

let size = nextLong() & 0x3fffffff
console.log('Original code bytes: ' + size * 4)

// Trim trailing zeros and nops
while ([0, NOP].includes(buf.readUInt32BE((offset + 1 + size) * 4))) {
  size--
}

console.log('Truncated code bytes: ' + size * 4)
const totalBytes = (offset + 3 + size) * 4
console.log('Total bytes: ' + totalBytes)

// Truncate data, leaving one extrra longword
const truncated = buf.slice(0, totalBytes)

// Update size
truncated.writeUInt32BE(size, (offset + 1) * 4)
// Write end marker
truncated.writeUInt32BE(HUNK_END, totalBytes - 4)

fs.writeFileSync(outFile, truncated)
