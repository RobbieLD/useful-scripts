const path = require('path');
const fs = require('fs');
const readline = require('readline');
const events = require('events');
const TIME_OFFSET = 10;

const convertTime = (time) => {
    const parts = time.split(':');
    const hours = (Number.parseInt(parts[0]) + TIME_OFFSET) % 24;
    return `${hours}:${parts[1]}:${parts[2]}`;
}

const parseForLongRequests = async (input, min) => {
    const startRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2}\\sINF\\]\\s\\sHTTP\\sPOST\\s/api/Calculate\\sresponded\\s\\d{3}\\sin\\s\\d{${min.toString().length}}.\\d{4}\\sms`);
    const timeRegex = new RegExp(`\\d{${min.toString().length}}.\\d{4}`);
    const idRegex = new RegExp('[a-g0-9]{8}(-[a-g0-9]{4}){3}-[a-g0-9]{12}');
    const ids = [];
    let previousLine

    const rl = readline.createInterface({
        input: fs.createReadStream(input),
        crlfDelay: Infinity
    });

    rl.on('line', (line) => {
        if (startRegex.test(line)) {
            const time = Number.parseFloat(line.match(timeRegex)[0]);
            if (time > min) {
                ids.push(previousLine.match(idRegex)[0]);
            }
        }

        previousLine = line;
    });

    await events.once(rl, 'close');
    return ids;
};

const parseForQueryTime = async (input, id, pod) => {
    let totalLookups = 0;
    let totalDatabaseTime = 0;
    let totalTime = 0;
    let startTime, endTime;
    let longestQuery = 0;
    let grabTotalTime = false;
    let totalRequests = 0;
    let totalQueries = 0;
    let recordStats = false;

    const queryRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2}\\sINF\\]\\s${id}\\s->\\sLook\\sUp\\sConnection\\sQuery.*`);
    const timeRegex = new RegExp('\\d{2}:\\d{2}:\\d{2}.\\d{7}');
    const startRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2}\\sINF\\]\\sRequest\\scorrelation\\sid:\\s${id}\\sstarted`);
    const logTimeRegex = new RegExp('\\d{2}:\\d{2}:\\d{2}');
    const endRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2}\\sINF\\]\\sRequest\\scorrelation\\sid:\\s${id}\\sfinished`);
    const totalTimeRegex = new RegExp(`\\d*.\\d{4}`);

    const rl = readline.createInterface({
        input: fs.createReadStream(input),
        crlfDelay: Infinity
    });

    rl.on('line', (line) => {
        if (grabTotalTime) {
            totalTime = Number.parseFloat(line.match(totalTimeRegex)[0])
            grabTotalTime = false;
        } else if (startRegex.test(line)) {
            startTime = convertTime(line.match(logTimeRegex)[0]);
            recordStats = true;
        } else if (endRegex.test(line)) {
            endTime = convertTime(line.match(logTimeRegex)[0]);
            grabTotalTime = true;
            recordStats = false;
        } else if (queryRegex.test(line)) {
            const time = Number.parseFloat(`.${line.match(timeRegex)[0].split('.')[1]}`);
            if (time > longestQuery) {
                longestQuery = time;
            }

            totalDatabaseTime += time;
            totalLookups++
        } else {
            if (recordStats && line.includes('Query')) {
                totalQueries++;
            } else if (recordStats && line.includes('started')) {
                totalRequests++;
            }
        }
    });

    await events.once(rl, 'close');

    return {
        Start_Time: startTime,
        Request_Queries: totalLookups,
        Total_Database_Query_Time: totalDatabaseTime,
        Database_Percentage: `${(totalDatabaseTime / (totalTime / 1000)) * 100}%`,
        Longest_Running_Query: longestQuery,
        Total_Response_Time: totalTime / 1000,
        End_Time: endTime,
        Other_Requests: totalRequests,
        Other_Queries: totalQueries,
        Correlation_ID: id,
        Pod: pod
    }
};


const makeTable = (results) => {
    const columns = Object.keys(results[0]);
    const header = `| ${columns.join(' | ')} |`;
    const separator = '| - '.repeat(columns.length) + ' |';
    const lines = [header, separator]

    for (const result of results) {
        const values = Object.values(result);
        const line = `| ${values.join(' | ')} |`;
        lines.push(line);
    }

    return lines.join('\n');
}

// This means we can be async inside the main body of the code
(async () => {
    const logPath = path.resolve(process.argv[2]);
    const minTime = process.argv[3];
    const results = [];
    const logs = await fs.promises.readdir(logPath);
    
    for (const log of logs) {
        const file = path.resolve(logPath, log)
        const pod = path.basename(log, path.extname(log));
        const ids = await parseForLongRequests(file, minTime);
        for (const id of ids) {
             results.push(await parseForQueryTime(file, id, pod));
        }
    }

    results.sort((a, b) => b.Total_Response_Time - a.Total_Response_Time);
    console.log(results);

    // Write the output to a file
    if (process.argv.length === 5) {
        const output = path.resolve(process.argv[4]);
        await fs.promises.writeFile(output, makeTable(results))
    }
})();
