/**
 * Created by Victor on 2014/6/13.
 */
/*jslint node:true*/
/*global process*/
var html2markdown = require('html2markdown'),
    fs = require('fs'),
    args = process.argv.splice(2),
    htmlFile = args[0],
    markdownFile = args[1],
    html,
    markdown;

html = fs.readFileSync(htmlFile, { encoding: 'utf8' });
markdown = html2markdown(html, { inlineStyle: true });
fs.writeFileSync(markdownFile, markdown);
