#!groovy
@Library('mapillary-pipeline') _
com.mapillary.pipeline.Pipeline.builder(this, steps)
    .withSetupIosStage()
    .withBuildIosStage()
    .withUnitIosStage()
    .build()
    .execute()
