// Imports
const parse = require('csv-parse')
const transform = require('stream-transform')
const fs = require('fs');
const path = require('path')

// Globals
let testCaseNumber = 1
let args = {
    params: [],
    format() {
        return this.params.map(p => p.typeName + ' ' + p.paramName).join(',')
    }
}

const testCases = []

// Setup
console.log('Processing File: ' + process.argv[2])
const fullPath = path.resolve(process.argv[2])
console.log('Path: ' + fullPath)
const namespace = fullPath.replace(/^.*[\\\/]/, '').split('.')[0]
console.log('Namespace: ' + namespace)
const testName = Array.from(namespace.matchAll(/[A-Z]{1}[a-z]+|\d+/g)).filter(s => s[0] !== 'Var').map(s => s[0].toLowerCase()).join('_')
console.log('Test Class: ' + testName)

// File Contents
let contents = 'using NUnit.Framework;\n' +
    'using Shouldly;\n' +
    'using Stratos.Youi.Calc.Assemblies.Perils.Test.Helpers;\n' +
    '\n' +
    'namespace Stratos.Youi.Calc.Assemblies.Perils.Test.UserFunctions.Underwriting.' + namespace + '\n' +
    '{\n' +
    '\t[TestFixture]\n' +
    '\t[Parallelizable(ParallelScope.None)]\n' +
    '\tpublic class ' + testName + ' : TestBase \n' +
    '\t{\n'


// Functions
const parser = parse({ columns: true })

const transformer = transform((record, callback) => {
    const values = Object.values(record)
    const testArgs = []

    values.forEach((v,i) => {
        switch (args.params[i].typeName) {
            case 'int':
                testArgs.push(Number.parseInt(v) || 0)
                break
            case 'double':
                testArgs.push(Number.parseFloat(v) || 0)
                break
            case 'bool':
                testArgs.push(v.toLowerCase())
                break
            default:
                testArgs.push(`"${v}"`)
        }
    })

    const testCase = `[TestCase(${testArgs.join(', ')}, TestName = "${testCaseNumber}")]`
    testCaseNumber++

    callback(null, testCase)
}, {
    parallel: 5
})

const argsBuilder = (record) => {
    const headers = Object.keys(record)
    headers.forEach(h => {
        h = h.toLowerCase().trim()
        let word = ''
        
        h.split('_').forEach((w, i) => {
            if (i === 0) {
                word = w
            } else {
                word += w[0].toUpperCase() + w.substr(1, w.length)
            }
        })

        const parts = word.split('@')
        const arg = {}

        if (parts.length > 1) {

            let typeName = ''

            switch (parts[0]) {
                case 'i':
                    typeName = 'int'
                    break
                case 'd':
                    typeName = 'double'
                    break
                case 'b':
                    typeName = 'bool'
                default:
                    throw Error(parts[0] + ' is not a valid data type')
            }

            arg.typeName = typeName
            arg.paramName = parts[1]
        } else {
            arg.typeName = 'string'
            arg.paramName = parts[0]
        }

        args.params.push(arg)
    })
}

const writter = () => {
    contents +=
        testCases.reduce((tcs, tc) => tcs += `\t\t${tc}\n`, '') +
        '\t\tpublic void gets_correct_classifications(' + args.format() + ')\n' +
        '\t\t{\n' +
        '\t\t\tvar parameters = new Parameters().SetDefault("Risk", "PerilGroup");\n' +
        '\t\t\t/// params\n' +
        '\t\t\tvar result = new Shared.UserFunctions.' + namespace + '().V1(parameters);\n' +
        '\t\t\tresult.Value.ShouldBe(expectedOutcome);\n' +
        '\t\t}\n' +
        '\t}\n' +
        '}\n'

    fs.createWriteStream('./' + namespace + '.cs').write(contents)
}

fs.createReadStream(fullPath)
    .pipe(parser)
    .once('data', (record) => argsBuilder(record))
    .pipe(transformer)
    .on('data', (test) => testCases.push(test))
    .on('end', () => writter())
