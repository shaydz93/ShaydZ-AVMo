// Shared console utilities for iOS integration scripts
const chalk = require('chalk');

class ConsoleUtils {
    static info(message) {
        console.log(chalk.blue('ℹ'), message);
    }
    
    static success(message) {
        console.log(chalk.green('✓'), message);
    }
    
    static warning(message) {
        console.log(chalk.yellow('⚠'), message);
    }
    
    static error(message) {
        console.log(chalk.red('✗'), message);
    }
    
    static header(title) {
        console.log('\n' + chalk.bold.cyan('=' + '='.repeat(title.length + 2) + '='));
        console.log(chalk.bold.cyan('| ' + title + ' |'));
        console.log(chalk.bold.cyan('=' + '='.repeat(title.length + 2) + '=') + '\n');
    }
    
    static section(title) {
        console.log(chalk.bold.magenta('\n→ ' + title));
    }
    
    static progress(message) {
        process.stdout.write(chalk.blue('  ⟳ ' + message + '...'));
    }
    
    static clearProgress() {
        process.stdout.clearLine();
        process.stdout.cursorTo(0);
    }
    
    static table(data) {
        console.table(data);
    }
}

module.exports = ConsoleUtils;
