#!groovy
@Library('mapillary-pipeline') _
com.mapillary.pipeline.Pipeline.builder(this, steps)
    .withSetupIosStage()
    .withBuildAppStage()
    .withUnitAppStage()
    .build()
    .execute()
