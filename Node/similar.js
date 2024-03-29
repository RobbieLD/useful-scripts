const LevenshteinDistance = (s1, s2, opts = {}) => {
    const insWeight = 'insWeight' in opts ? opts.insWeight : 1;
    const delWeight = 'delWeight' in opts ? opts.delWeight : 1;
    const subWeight = 'subWeight' in opts ? opts.subWeight : 1;
    const useDamerau = 'useDamerau' in opts ? opts.useDamerau : true;

    // Ignore case
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    let d = [];

    if (s1.length === 0) {
        // if s1 string is empty, just insert the s2 string
        return s2.length * insWeight;
    }

    if (s2.length === 0) {
        // if s2 string is empty, just delete the s1 string
        return s1.length * delWeight;
    }

    // Init the matrix
    for (let i = 0; i <= s1.length; i += 1) {
        d[i] = [];
        d[i][0] = i * delWeight;
    }

    for (let j = 0; j <= s2.length; j += 1) {
        d[0][j] = j * insWeight;
    }

    for (let i = 1; i <= s1.length; i += 1) {
        for (let j = 1; j <= s2.length; j += 1) {
            let subCostIncrement = subWeight;
            if (s1.charAt(i - 1) === s2.charAt(j - 1)) {
                subCostIncrement = 0;
            }

            const delCost = d[i - 1][j] + delWeight;
            const insCost = d[i][j - 1] + insWeight;
            const subCost = d[i - 1][j - 1] + subCostIncrement;

            let min = delCost;
            if (insCost < min) min = insCost;
            if (subCost < min) min = subCost;


            if (useDamerau) {
                if (i > 1 && j > 1
                    && s1.charAt(i - 1) === s2.charAt(j - 2)
                    && s1.charAt(i - 2) === s2.charAt(j - 1)) {
                    const transCost = d[i - 2][j - 2] + subCostIncrement;

                    if (transCost < min) min = transCost;
                }
            }


            d[i][j] = min;
        }
    }

    return d[s1.length][s2.length];
}


console.log(LevenshteinDistance('hello', 'hello'))
console.log(LevenshteinDistance('hello', 'Hello'))
console.log(LevenshteinDistance('hello', 'hell0'))
console.log(LevenshteinDistance('hello', 'hell'))
console.log(LevenshteinDistance('hello', 'helloo'))
console.log(LevenshteinDistance('hello', 'kjfdgh'))
console.log(LevenshteinDistance('hello', '1234'))
