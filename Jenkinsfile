#!groovy
@Library('mapillary-pipeline@build_ios') _
com.mapillary.pipeline.Pipeline.builder(this, steps)
    .withBuildIosStage()
    .withUnitIosStage()
    .build()
    .execute()
