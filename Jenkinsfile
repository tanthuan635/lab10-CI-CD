pipeline {
    agent any

    tools {
        nodejs 'NodeJS 24'
    }

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        booleanParam(
            name: 'DEPLOY_ENABLED',
            defaultValue: true,
            description: 'Deploy the successful React build on this Windows agent.'
        )
        string(
            name: 'DEPLOY_DIR',
            defaultValue: 'D:\\WebServer\\ReactApp',
            description: 'Absolute directory served by the web server.'
        )
        string(
            name: 'BACKUP_DIR',
            defaultValue: 'D:\\WebServer\\Backups',
            description: 'Absolute directory in which timestamped backups are kept.'
        )
    }

    environment {
        CI = 'true'
        NPM_CONFIG_CACHE = "${WORKSPACE}\\.npm-cache"
    }

    stages {
        stage('Checkout') {
            steps {
                // Let the Jenkins SCM plugin own the workspace. Do not run git pull
                // or git reset from a Pipeline workspace.
                checkout scm
            }
        }

        stage('Preflight') {
            steps {
                bat '''
@echo off
setlocal EnableExtensions

if /I not "%OS%"=="Windows_NT" (
    echo ERROR: This Pipeline requires a Windows Jenkins agent.
    exit /b 1
)

where node.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: node.exe is not available on the Jenkins service account PATH.
    exit /b 1
)

where npm.cmd >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm.cmd is not available on the Jenkins service account PATH.
    exit /b 1
)

if not exist "%WORKSPACE%\\package.json" (
    echo ERROR: package.json was not checked out into %WORKSPACE%.
    exit /b 1
)

if not exist "%WORKSPACE%\\package-lock.json" (
    echo ERROR: package-lock.json is required so npm ci can produce a repeatable build.
    exit /b 1
)

node --version
call npm --version
'''
            }
        }

        stage('Install') {
            steps {
                bat 'call npm ci --no-audit --no-fund'
            }
        }

        stage('Test') {
            steps {
                bat 'call npm test'
            }
        }

        stage('Build') {
            steps {
                bat '''
@echo off
set "VITE_BUILD_VERSION=%BUILD_NUMBER%-%GIT_COMMIT:~0,7%"
call npm run build
'''
                script {
                    // This project emits build/. Prefer it so an untracked dist/
                    // left by an older configuration can never be deployed.
                    if (fileExists('build/index.html')) {
                        env.BUILD_OUTPUT = 'build'
                    } else if (fileExists('dist/index.html')) {
                        env.BUILD_OUTPUT = 'dist'
                    } else {
                        error('Build succeeded but neither dist/index.html nor build/index.html exists.')
                    }
                }
                archiveArtifacts artifacts: "${env.BUILD_OUTPUT}/**", fingerprint: true
            }
        }

        stage('Backup and deploy') {
            when {
                expression { return params.DEPLOY_ENABLED }
            }
            steps {
                bat '''
@echo off
call "%WORKSPACE%\\scripts\\deploy.bat" "%WORKSPACE%\\%BUILD_OUTPUT%" "%DEPLOY_DIR%" "%BACKUP_DIR%"
if errorlevel 1 exit /b %errorlevel%
'''
            }
        }
    }

    post {
        success {
            echo "Build ${env.BUILD_TAG} completed successfully."
        }
        failure {
            echo "Build ${env.BUILD_TAG} failed. Review the first failing stage above."
        }
    }
}
