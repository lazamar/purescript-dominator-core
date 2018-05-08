
const lineLength = 100;
const tabWidth = 4

module.exports = {
    "extends": ["eslint:recommended", "prettier"],
    "plugins": ["html", "prettier"],// activating esling-plugin-prettier (--fix stuff) 
    "env": {
        "es6": true,
        "browser": true,
        "node": true
    },
    "globals": {},
    "rules": {
        "prettier/prettier":[ "error", 
            {
                "tabWidth": tabWidth,
                "printWidth": lineLength,
            }],
        "no-return-assign": [0],
        "no-multiple-empty-lines": "error",
        "arrow-body-style": ["error", "as-needed"],
        "no-use-before-define": [
            2,
            {
                "functions": false,
                "classes": true,
                "variables": true
            }
        ],
        "no-redeclare": 0,
        "no-console": "error",
        "no-unused-vars": [ 2, { "argsIgnorePattern": "^_" } ],
        "global-require": "error"
    }
}