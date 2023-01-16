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
    const startRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2}.\\d{1,7}\\sINF\\]\\s\\sHTTP\\sPOST\\s/api/Calculate\\sresponded\\s\\d{3}\\sin\\s\\d{4,8}.\\d*\\sms\\sfor\\sid:\\s.*`);
    const timeRegex = new RegExp(`\\d{4,8}.\\d{4}`);
    const idRegex = new RegExp('[a-g0-9]{8}(-[a-g0-9]{4}){3}-[a-g0-9]{12}');
    const ids = [];

    const rl = readline.createInterface({
        input: fs.createReadStream(input),
        crlfDelay: Infinity
    });

    rl.on('line', (line) => {
        if (startRegex.test(line)) {
            const time = Number.parseFloat(line.match(timeRegex)[0]);
            if (time > min) {
                ids.push(line.match(idRegex)[0]);
            }
        }

        previousLine = line;
    });

    await events.once(rl, 'close');
    return ids;
};

const parseForQueryTime = async (input, id) => {
    let totalLookups = 0;
    let totalDatabaseTime = 0;
    let totalTime = 0;
    let startTime, endTime;
    let longestQuery = 0;
    let totalRequests = 0;
    let totalQueries = 0;
    let totalDatabaseConnectionTime = 0;
    let recordStats = false;

    const queryRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2,4}.\\d{1,7}\\sINF\\]\\s${id}\\s->\\sLook\\sUp\\sConnection\\sQuery.*`);
    const connectionRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2,4}.\\d{1,7}\\sINF\\]\\s${id}\\s->\\sLook\\sUp\\sConnection\\sOpen.*`);
    const timeRegex = new RegExp('\\s\\d{2}:\\d{2}:\\d{2,4}.\\d{1,7}');
    const startRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2,4}.\\d{1,7}\\sINF\\]\\sRequest\\scorrelation\\sid:\\s${id}\\sstarted`);
    const logTimeRegex = new RegExp('\\d{2}:\\d{2}:\\d{2,4}.\\d{1,7}');
    const endRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2,4}.\\d{1,7}\\sINF\\]\\sRequest\\scorrelation\\sid:\\s${id}\\sfinished`);
    const totalTimeRegex = new RegExp(`\\d{4,8}.\\d{4,8}`);
    const responseRegex = new RegExp(`\\[\\d{2}:\\d{2}:\\d{2,4}.\\d{1,7}\\sINF\\]\\s\\sHTTP\\sPOST\\s/api/Calculate\\sresponded\\s\\d{3}\\sin\\s\\d{4,8}.\\d*\\sms\\sfor\\sid:\\s${id}`);

    const rl = readline.createInterface({
        input: fs.createReadStream(input),
        crlfDelay: Infinity
    });

    rl.on('line', (line) => {
        try {
            if (responseRegex.test(line)) {
                totalTime = Number.parseFloat(line.match(totalTimeRegex)[0]);
            } else if (startRegex.test(line)) {
                startTime = convertTime(line.match(logTimeRegex)[0]);
                recordStats = true;
            } else if (endRegex.test(line)) {
                endTime = convertTime(line.match(logTimeRegex)[0]);
                recordStats = false;
            } else if (queryRegex.test(line)) {
                const qTime = Number.parseFloat(line.match(timeRegex)[0].split(':')[2]);
                if (qTime > longestQuery) {
                    longestQuery = qTime;
                }

                totalDatabaseTime += qTime;
                if (id === 'd1b078f4-25dd-4933-b32a-525f0fce75a2') {
                    console.log(line);
                    console.log(qTime);
                    console.log(totalDatabaseTime);
                    console.log(totalLookups);
                }
                totalLookups++;
            } else if (connectionRegex.test(line)) {
                const cTime = Number.parseFloat(line.match(timeRegex)[0].split(':')[2]);
                totalDatabaseConnectionTime += cTime;
            } else {
                if (recordStats && line.includes('Query')) {
                    totalQueries++;
                } else if (recordStats && line.includes('started')) {
                    totalRequests++;
                }
            }
        }
        catch (error) {
            console.log(line);
            console.error(error);
        }
    });

    await events.once(rl, 'close');

    return {
        Start_Time: startTime,
        Request_Queries: totalLookups,
        Total_Database_Query_Time: totalDatabaseTime,
        Total_Database_Connection_Time: totalDatabaseConnectionTime,
        Database_Percentage: `${(totalDatabaseTime / (totalTime / 1000)) * 100}%`,
        Longest_Running_Query: longestQuery,
        Total_Response_Time: totalTime / 1000,
        End_Time: endTime,
        Other_Requests: totalRequests,
        Other_Queries: totalQueries,
        Correlation_ID: id
    }
};


const makeMarkDownTable = (results) => {
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

const makeHtmlTable = (results) => {
    const columns = Object.keys(results[0]);
    const header = `<thead><tr><th>${columns.join('</th><th>')}</th></tr></thead>`;
    const lines = [header, '<tbody>'];

    for (const result of results) {
        const values = Object.values(result);
        lines.push(`<tr><td>${values.join('</td><td>')}</td></tr>`);
    }

    lines.push('</tbody>');
    return lines.join('\n');
}

// This means we can be async inside the main body of the code
(async () => {
    const logPath = path.resolve(process.argv[2]);
    const minTime = process.argv[3];
    const results = [];
        
    const file = path.resolve(logPath, 'merge.log')
    const ids = await parseForLongRequests(file, minTime);
    for (const id of ids) {
        results.push(await parseForQueryTime(file, id));
    }

    results.sort((a, b) => b.Total_Response_Time - a.Total_Response_Time);
    console.log("Results");
    console.log(results);

    // Write the output to a file
    if (process.argv.length === 5 && results.length) {
        const output = path.resolve(process.argv[4]);
        const templatePath = path.resolve('table.html');
        const template = (await fs.promises.readFile(templatePath)).toString();
        const contents = template.replace('{content}', makeHtmlTable(results));
        await fs.promises.writeFile(output, contents);
    }
})().catch(e => console.error(e));
