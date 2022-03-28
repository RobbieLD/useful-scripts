const events = require('events');
const fs = require('fs');
const readline = require('readline');
const path = require('path')

const inputFile = path.resolve(process.argv[2])

const results = []
const test = 'retries with correlation id';

(async function processLineByLine() {
    try {
        const rl = readline.createInterface({
            input: fs.createReadStream(inputFile),
            crlfDelay: Infinity
        })

        rl.on('line', (line) => {
            if (line.includes(test)) {
                const chunks = line.split(' ');
                results.push(chunks[chunks.length - 1])
            }
        })

        await events.once(rl, 'close');
        console.log(`Found ${results.length} lines that match`)
        fs.createWriteStream(`${path.basename(inputFile, path.extname(inputFile))}.txt`).write(results.join('\n'))
    }
    catch (err) {
        console.error(err);
    }
})();
