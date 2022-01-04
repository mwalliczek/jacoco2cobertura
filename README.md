# jacoco2cobertura

Docker image to allow java projects that use jacoco to use the new codecoverage feature of gitlab.

Forked from https://gitlab.com/haynes/jacoco2cobertura/.

Adapted to build for amd64, arm64 and arm/v7

The image includes 2 scripts.
* cover2cover.py (forked from https://github.com/rix0rrr/cover2cover ; includes open PRs in that repo)
  * Converts jacoco xml reports to cobertura xml reports
    
# Prerequisites  
Currently the `cover2cover.py` expects jacoco xmls that follow the version 1.1 of the report format.  
This means jacoco > 0.8.2 is required.  


# Usage:

```yaml
stages:
  - build
  - test
  - visualize
  - deploy

test-jdk11:
  stage: test
  image: maven:3.6.3-jdk-11
  script:
    - 'mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report'
  artifacts:
    paths:
      - target/site/jacoco/jacoco.xml

coverage-jdk11:
  stage: visualize
  image: haynes/jacoco2cobertura:1.0.7
  script:
    - 'python /opt/cover2cover.py target/site/jacoco/jacoco.xml $CI_PROJECT_DIR/src/main/java/ > target/site/coverage.xml'
  needs: ["test-jdk11"]
  dependencies:
    - test-jdk11
  artifacts:
    reports:
      cobertura: target/site/coverage.xml
```

# Multi modules:

Use the report-aggregate goal of the jacoco-maven-plugin. 
See this project for an example of how to correctly configure jacoco in multimodule projects:
https://github.com/jacoco/jacoco/tree/master/jacoco-maven-plugin.test/it/it-report-aggregate

If you use something like this structure:

* dao
  * dao-api
  * dao-impl
* core
  * core-api
  * core-impl
* web
* main
  * production
  * develop

Or don`t have one module evidently depend of all. Like web production depend of
web core-impl dao-impl, core-impl depend of dao-api and core-api. 
```xml
   ...
    <groupId>...</groupId>
    <artifactId>jacoco</artifactId>
    <dependencies>
        <dependency>
            <groupId>...</groupId>
            <artifactId>dao-api</artifactId>
            <version>...</version>
        </dependency>

        <dependency>
            <groupId>...</groupId>
            <artifactId>dao-impl</artifactId>
            <version>...</version>
        </dependency>

        <dependency>
            <groupId>...</groupId>
            <artifactId>core-api</artifactId>
            <version>...</version>
        </dependency>

        <dependency>
            <groupId>...</groupId>
            <artifactId>core-impl</artifactId>
            <version>...</version>
        </dependency>

        <dependency>
            <groupId>...</groupId>
            <artifactId>web</artifactId>
            <version>...</version>
        </dependency>

        <dependency>
            <groupId>...</groupId>
            <artifactId>developer</artifactId>
            <version>...</version>
        </dependency>

        <dependency>
            <groupId>...</groupId>
            <artifactId>production</artifactId>
            <version>...</version>
        </dependency>

    </dependencies>

```
```yaml
stages:
  - build
  - test
  - visualize
  - deploy

test-jdk11:
  stage: test
  image: maven:3.6.3-jdk-11
  script:
    - 'mvn $MAVEN_CLI_OPTS clean 
                           org.jacoco:jacoco-maven-plugin:prepare-agent
                           test
                           org.jacoco:jacoco-maven-plugin:report-aggregate'
  after_script:
    - cat jacoco/target/site/jacoco-aggregate/index.html | grep -o '<tfoot>.*</tfoot>'
  artifacts:
    paths:
      - jacoco/target/site/jacoco-aggregate/jacoco.xml

coverage-jdk11:
  stage: visualize
  image: haynes/jacoco2cobertura:1.0.7
  script:
    # all module add to args
    - 'python /opt/cover2cover.py jacoco/target/site/jacoco-aggregate/jacoco.xml 
              $CI_PROJECT_DIR/dao/dao-api/src/main/java/
              $CI_PROJECT_DIR/dao/dao-impl/src/main/java/
              $CI_PROJECT_DIR/core/core-api/src/main/java/
              $CI_PROJECT_DIR/core/core-impl/src/main/java/
              $CI_PROJECT_DIR/web/src/main/java/
              $CI_PROJECT_DIR/main/develop/src/main/java/
              $CI_PROJECT_DIR/main/production/src/main/java/
              > jacoco/target/site/coverage.xml'
  needs: ["test-jdk11"]
  dependencies:
    - test-jdk11
  artifacts:
    reports:
      cobertura: jacoco/target/site/coverage.xml
```

You can also change the coverage job to dynamically find all java source repositories. With this, you avoid the need to add a new directory every time you add a new source folder.
The needed configuration is the same as in the previous example, but you need to edit the script of `coverage-jdk11` job to:

```yaml
coverage-jdk11:
  script:
    # find all modules containing java source files.
    - jacoco_paths=`find * -path "**/src/main/java" -type d | sed -e 's@^@'"$CI_PROJECT_DIR"'/@'`
    - python /opt/cover2cover.py jacoco/target/site/jacoco-aggregate/jacoco.xml $jacoco_paths > jacoco/target/site/coverage.xml
```
