#!groovy
@Library('mapillary-pipeline') _
com.mapillary.pipeline.Pipeline.builder(this, steps)
    .withSetupIosStage()
    .withBuildApplicationStage()
    .withUnitAppStage()
    .build()
    .execute()
