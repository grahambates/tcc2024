const fs = require("fs")
const { argv } = require("process")

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

const patchSize = parseInt(argv[4], 16)

const buf = fs.readFileSync(inFile)

let offset = 0
const nextLong = () => buf.readUInt32BE((offset++) * 4)

const hunkType = nextLong()
if (hunkType !== 0x3f3) {
  console.error('Expected hunk header type: ' + hunkType.toString(16))
  process.exit()
}

while (nextLong() !== 0) { } // skip strings

const tableSize = nextLong()
const firstHunk = nextLong()
const lastHunk = nextLong()
console.log({ tableSize, firstHunk, lastHunk })

if (tableSize !== 1 || firstHunk !== 0 || lastHunk !== 0) {
  console.error('Expected exactly 1 hunk')
  process.exit(1)
}

for (let i = 0; i < (lastHunk - firstHunk + 1); i++) {
  const val = nextLong()
  const type = val >> 30
  const size = val & 0x3fffffff
  console.log({ type, size })
  if (patchSize) {
    console.log(`patching to size ${patchSize}`)
    buf.writeInt32BE(patchSize + (type << 30), (offset - 1) * 4)
  }
}

fs.writeFileSync(outFile, buf)
