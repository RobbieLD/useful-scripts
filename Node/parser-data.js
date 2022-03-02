// Imports
const parse = require('csv-parse')
const transform = require('stream-transform')
const fs = require('fs');
const path = require('path')

// Config
const inputFile = path.resolve('sample.csv')
const headingFile = path.resolve('headings.txt')

// Global
const headings = fs.readFileSync(headingFile, 'utf-8').split(',')
let progress = 0

// Parser
const parser = parse({ columns: true })

// Global
const file = fs.createWriteStream('./results.csv')

// Write the header line
file.write(headings.join() + '\n')

// Helpers
const makeDictionary = (items, key) => {
    const dictionary = {
        'LOOKUP_KEY' : key
    }

    for (let index = 0; index < items.length - 1; index += 2) {
        dictionary[items[index]] = items[index + 1]
    }

    return dictionary
}


// Transformers
const transformer = transform((record, callback) => {
    progress++
    const values = Object.values(record)

    const parts = values[3].split('|')
    const dictionary = makeDictionary(parts, values[1])
    
    const row = []
    headings.forEach(h => {
        if (dictionary[h]) {
            row.push(dictionary[h])
        } else {
            // What should missing values be?
            row.push('')
        }
    })

    if (progress % 1000 === 0) {
        console.log(progress)
    }

    callback(null, row.join() + '\n')
}, {
    parallel: 5
})

// Parse the file
fs.createReadStream(inputFile)
    .pipe(parser)
    .pipe(transformer)
    .pipe(file)
