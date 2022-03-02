// Imports
const parse = require('csv-parse')
const transform = require('stream-transform')
const fs = require('fs');
const path = require('path')

// Config
const inputFile = path.resolve('sample.csv')

// Global
const headings = ['LOOKUP_KEY']
let progress = 0

// Parser
const parser = parse({ columns: true })

// Transformers
const transformer = transform((record, callback) => {
    progress++
    const values = Object.values(record)
    const parts = values[3].split('|')
    const rowHeadings = parts.filter((_, index) => index % 2 == 0)

    if (progress % 1000 === 0) {
        console.log(progress)
    }

    callback(null, rowHeadings.filter(x => !headings.includes(x)))
}, {
    parallel: 1
})

// Parse the file
fs.createReadStream(inputFile)
    .pipe(parser)
    .pipe(transformer)
    .on('data', (additionalHeadings) => headings.push(...additionalHeadings))
    .on('end', () => fs.createWriteStream('./headings.txt').write(headings.join()))
