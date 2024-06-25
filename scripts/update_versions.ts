#!/usr/bin/env bun
import { read, readFileSync, readdirSync, writeFileSync } from "fs";

// read folder features and get all the versions
const features = readdirSync("../features/src");

function readJson(path: string) {
  const content = readFileSync(path, "utf-8");
  // strip comment lines
  const lines = content
    .split("\n")
    .filter((line) => !line.trim().startsWith("//"));
  return JSON.parse(lines.join("\n"));
}

const versions = {};
for (const feature of features) {
  // read devcontainer-feature.json and get the version
  const devcontainerFeature = readJson(
    `../features/src/${feature}/devcontainer-feature.json`
  );
  versions[feature] = devcontainerFeature.version;
}

const devcontainers = readdirSync("../devcontainers");
for (const devcontainer of devcontainers) {
  // read devcontainer.json and update the version
  const devcontainerJson = readJson(
    `../devcontainers/${devcontainer}/.devcontainer.json`
  );

  const installedFeatures = features.filter((feature) =>
    Object.keys(devcontainerJson.features).some((installedFeature) =>
      installedFeature.startsWith(
        `ghcr.io/onezerocompany/devcontainers/features/${feature}`
      )
    )
  );

  const newFeatures = {};
  for (const installedFeature of installedFeatures.sort((a, b) =>
    a === "common-utils" ? 1 : -1
  )) {
    newFeatures[
      `ghcr.io/onezerocompany/devcontainers/features/${installedFeature}:${versions[installedFeature]}`
    ] = {};
  }

  devcontainerJson.features = newFeatures;
  writeFileSync(
    `../devcontainers/${devcontainer}/.devcontainer.json`,
    JSON.stringify(devcontainerJson, null, 2)
  );

  console.log(`Updated ${devcontainer}`);
}
