//seed: Seed 3799479735 1013904223
module.exports = ({code}) => {
    const line = `var $author$project$Main$ourInitialSeed = $elm$random$Random$initialSeed(1337)`;
    return code.replace(line, `var $author$project$Main$ourInitialSeed = { "$": "Seed", a: 3799479735, b: 1013904223 }`);
}
