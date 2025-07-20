#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const ConsoleUtils = require('./utils/console-utils');

class XcodeValidation {
    constructor() {
        this.projectPath = path.join(__dirname, '..', '..');
        this.issues = [];
    }

    async validateProject() {
        ConsoleUtils.header('Xcode Project Validation');
        
        try {
            await this.checkProjectStructure();
            await this.checkSwiftFiles();
            await this.checkInfoPlist();
            await this.checkAssets();
            await this.generateReport();
            
        } catch (error) {
            ConsoleUtils.error(`Validation failed: ${error.message}`);
            return false;
        }
        
        return this.issues.length === 0;
    }

    async checkProjectStructure() {
        ConsoleUtils.section('Checking Project Structure');
        
        const requiredFiles = [
            'ShaydZ-AVMo.xcodeproj/project.pbxproj',
            'ShaydZ-AVMo/ShaydZAVMoApp.swift',
            'ShaydZ-AVMo/ContentView.swift',
            'ShaydZ-AVMo/Info.plist'
        ];

        for (const file of requiredFiles) {
            const filePath = path.join(this.projectPath, file);
            if (!fs.existsSync(filePath)) {
                this.issues.push(`Missing required file: ${file}`);
                ConsoleUtils.error(`✗ Missing: ${file}`);
            } else {
                ConsoleUtils.success(`✓ Found: ${file}`);
            }
        }
    }

    async checkSwiftFiles() {
        ConsoleUtils.section('Checking Swift Files');
        
        const swiftFiles = this.getAllSwiftFiles();
        ConsoleUtils.info(`Found ${swiftFiles.length} Swift files`);
        
        for (const file of swiftFiles) {
            try {
                const content = fs.readFileSync(file, 'utf8');
                this.validateSwiftContent(file, content);
            } catch (error) {
                this.issues.push(`Cannot read Swift file: ${file} - ${error.message}`);
                ConsoleUtils.error(`✗ Cannot read: ${path.relative(this.projectPath, file)}`);
            }
        }
    }

    getAllSwiftFiles() {
        const swiftFiles = [];
        
        function scanDirectory(dir) {
            const items = fs.readdirSync(dir);
            
            for (const item of items) {
                const fullPath = path.join(dir, item);
                const stat = fs.statSync(fullPath);
                
                if (stat.isDirectory() && !item.includes('.xcodeproj')) {
                    scanDirectory(fullPath);
                } else if (item.endsWith('.swift')) {
                    swiftFiles.push(fullPath);
                }
            }
        }
        
        scanDirectory(path.join(this.projectPath, 'ShaydZ-AVMo'));
        return swiftFiles;
    }

    validateSwiftContent(file, content) {
        const fileName = path.relative(this.projectPath, file);
        
        // Check for common Swift issues
        const issues = [];
        
        // Check for missing imports
        if (!content.includes('import Foundation') && !content.includes('import SwiftUI')) {
            if (content.includes('struct ') || content.includes('class ') || content.includes('enum ')) {
                issues.push('Missing Foundation or SwiftUI import');
            }
        }
        
        // Check for unbalanced braces
        const openBraces = (content.match(/{/g) || []).length;
        const closeBraces = (content.match(/}/g) || []).length;
        if (openBraces !== closeBraces) {
            issues.push('Unbalanced braces');
        }
        
        // Check for potential syntax issues
        if (content.includes('func ') && !content.includes('{')) {
            issues.push('Function without body');
        }
        
        if (issues.length > 0) {
            ConsoleUtils.warning(`⚠ ${fileName}: ${issues.join(', ')}`);
            this.issues.push(...issues.map(issue => `${fileName}: ${issue}`));
        } else {
            ConsoleUtils.success(`✓ ${fileName}`);
        }
    }

    async checkInfoPlist() {
        ConsoleUtils.section('Checking Info.plist');
        
        const plistPath = path.join(this.projectPath, 'ShaydZ-AVMo', 'Info.plist');
        
        try {
            const content = fs.readFileSync(plistPath, 'utf8');
            
            const requiredKeys = [
                'CFBundleDisplayName',
                'CFBundleIdentifier',
                'CFBundleVersion',
                'CFBundleShortVersionString'
            ];
            
            for (const key of requiredKeys) {
                if (!content.includes(key)) {
                    this.issues.push(`Missing Info.plist key: ${key}`);
                    ConsoleUtils.error(`✗ Missing key: ${key}`);
                } else {
                    ConsoleUtils.success(`✓ Found key: ${key}`);
                }
            }
            
        } catch (error) {
            this.issues.push(`Cannot read Info.plist: ${error.message}`);
            ConsoleUtils.error('✗ Cannot read Info.plist');
        }
    }

    async checkAssets() {
        ConsoleUtils.section('Checking Assets');
        
        const resourcesPath = path.join(this.projectPath, 'ShaydZ-AVMo', 'Resources');
        
        if (fs.existsSync(resourcesPath)) {
            const items = fs.readdirSync(resourcesPath);
            ConsoleUtils.success(`✓ Resources directory found with ${items.length} items`);
            
            // Check for app icon
            const appIconPath = path.join(resourcesPath, 'AppIcon.appiconset');
            if (fs.existsSync(appIconPath)) {
                ConsoleUtils.success('✓ App icon set found');
            } else {
                ConsoleUtils.warning('⚠ App icon set not found');
            }
        } else {
            ConsoleUtils.warning('⚠ Resources directory not found');
        }
    }

    async generateReport() {
        ConsoleUtils.section('Validation Summary');
        
        if (this.issues.length === 0) {
            ConsoleUtils.success('🎉 Project is ready for Xcode!');
            ConsoleUtils.info('All checks passed. You can open this project in Xcode.');
            
            ConsoleUtils.section('Next Steps');
            ConsoleUtils.info('1. Transfer this project to a macOS environment');
            ConsoleUtils.info('2. Open ShaydZ-AVMo.xcodeproj in Xcode');
            ConsoleUtils.info('3. Select your target device or simulator');
            ConsoleUtils.info('4. Build and run the project (⌘+R)');
            
        } else {
            ConsoleUtils.error(`❌ Found ${this.issues.length} issues that need to be fixed:`);
            this.issues.forEach((issue, index) => {
                ConsoleUtils.error(`${index + 1}. ${issue}`);
            });
            
            ConsoleUtils.section('Recommendations');
            ConsoleUtils.info('Fix the issues above before opening in Xcode');
        }
        
        // Additional info
        ConsoleUtils.section('Project Information');
        ConsoleUtils.info('Platform: iOS 15.0+');
        ConsoleUtils.info('Framework: SwiftUI + Combine');
        ConsoleUtils.info('Architecture: MVVM');
        ConsoleUtils.info('Backend: Node.js microservices');
    }
}

// Main execution
async function main() {
    const validator = new XcodeValidation();
    const isValid = await validator.validateProject();
    
    process.exit(isValid ? 0 : 1);
}

if (require.main === module) {
    main();
}

module.exports = XcodeValidation;
