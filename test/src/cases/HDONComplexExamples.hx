package cases;

import testcore.TestCase;
import testcore.Test;
import HDON;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

class HDONComplexExamples extends TestCase {

    public function test_write_complex_examples(test: Test) {
        #if sys
        var resourcesDir = Sys.getCwd() + 'src/resources';
        if (!FileSystem.exists(resourcesDir)) {
            FileSystem.createDirectory(resourcesDir);
        }

        // Example 1: Rich nested data with extends and implements
        var userData: Dynamic = {
            id: 12345,
            name: 'Alice Smith',
            email: 'alice@example.com',
            active: true,
            tags: ['admin', 'beta', '🚀'],
            profile: {
                address: {
                    street: '123 Main St',
                    city: 'Metropolis',
                    zip: '10101'
                },
                preferences: {
                    theme: 'dark',
                    languages: ['en', 'es'],
                    notifications: {
                        email: true,
                        sms: false
                    }
                }
            },
            sessions: [
                { device: 'web', lastActive: '2025-08-30T12:00:00Z' },
                { device: 'mobile', lastActive: '2025-08-29T08:15:00Z' }
            ],
            meta: null
        };
        var hUser = HDON.fromObject('examples.data.UserProfile', userData);
        hUser._extends = 'BaseModel';
        hUser._implements = ['ISerializable', 'IValidatable'];
        var userClass = hUser.stringify();
        var userPath = resourcesDir + '/UserProfile.hx';
        File.saveContent(userPath, userClass);
        test.assert(FileSystem.exists(userPath), 'UserProfile.hx written');
        test.assert(userClass.indexOf('implements ISerializable, IValidatable') != -1, 'UserProfile header contains implements');

        // Example 2: Application config with arrays and mixed types
        var configData: Dynamic = {
            version: '1.4.2',
            features: {
                payments: true,
                analytics: true,
                experimental: ['fast-path', 'edge-cache']
            },
            limits: {
                maxUsers: 10000,
                timeouts: { connectMs: 3000, readMs: 10000 }
            },
            endpoints: [
                { name: 'api', url: 'https://api.example.com' },
                { name: 'cdn', url: 'https://cdn.example.com' }
            ]
        };
        var hConfig = HDON.fromObject('examples.config.AppConfig', configData);
        var configClass = hConfig.stringify();
        var configPath = resourcesDir + '/AppConfig.hx';
        File.saveContent(configPath, configClass);
        test.assert(FileSystem.exists(configPath), 'AppConfig.hx written');
        test.assert(configClass.indexOf('@:data var _data') != -1, 'AppConfig has data marker');

        // Example 3: No package class with deep nesting and numbers
        var statsData: Dynamic = {
            counters: { users: 5012, orgs: 87, projects: 12904 },
            hist: {
                daily: [12, 15, 9, 22, 18, 30, 25],
                monthly: [120, 150, 190, 210]
            },
            notes: 'Performance baseline v2',
            flags: { maintenance: false }
        };
        var hStats = HDON.fromObject('NoPackageStats', statsData);
        hStats._extends = 'a.b.C';
        hStats._implements = ['IStats'];
        var statsClass = hStats.stringify();
        var statsPath = resourcesDir + '/NoPackageStats.hx';
        File.saveContent(statsPath, statsClass);
        test.assert(FileSystem.exists(statsPath), 'NoPackageStats.hx written');
        test.assert(statsClass.indexOf('class NoPackageStats extends a.b.C implements IStats') != -1, 'NoPackageStats header correct');

        // Example 4: Stress nested object depth and quoting/unquoting keys
        var deepData: Dynamic = {
            level1: {
                level2: {
                    level3: {
                        level4: {
                            value: 'deep',
                            arr: [ { k: 1 }, { k: 2 }, { k: 3 } ]
                        }
                    }
                }
            }
        };
        var hDeep = HDON.fromObject('examples.deep.Nested', deepData);
        var deepClass = hDeep.stringify();
        var deepPath = resourcesDir + '/Nested.hx';
        File.saveContent(deepPath, deepClass);
        test.assert(FileSystem.exists(deepPath), 'Nested.hx written');
        test.assert(deepClass.indexOf('level4:') != -1, 'Nested keys unquoted in class output');

        #else
        test.assert(true, 'sys not available, skipping file writes');
        #end
    }
}

