#!groovy
@Library('mapillary-pipeline@build_ios') _
com.mapillary.pipeline.Pipeline.builder(this, steps)
    .withSetupIosStage()
    .withBuildIosStage()
    .withUnitIosStage()
    .build()
    .execute()
