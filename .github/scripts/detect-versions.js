// Detects which maistra-builder versions have build-relevant changes.
//
// Called from GHA workflows via actions/github-script.
// Looks at which files changed in a PR or push, figures out which builder versions
// are affected and sets GHA outputs that downstream jobs use to build the right
// matrix of containers.
// Usage from actions/github-script:
//     const detect = require('./github/scripts/detect-versions.js');
//     await detect({ github, context, core, mode: 'pr', prNumber: 123 });
//     await detect({ github, context, core, mode: 'push' });
//     await detect({ github, context, core, mode: 'manual', version: '3.5' });
//
// Parameters:
// github, context, core => provided by actions/github-script automagically.
// mode   => Required, one of:
//  - 'pr' -> detect versions from files changed in a pull request. Requires prNumber
//  - 'push' -> detect versions from files changed in a push to main.
//              Uses context.payload.before/after 
//  - 'manual' -> skip detection, build a single explicit version. Requires version (e.g. '3.5')
// prNumber => PR number (required when mode is 'pr')
// version => version string like '3.5' or 'main' (required when mode is 'manual')
//
// GHA outputs set by this script:
// - needs_build => 'true' if there are versions to build, 'false' otherwise
// - versions => JSON array of version strings.. e.g. '["3.5", "main"]'
// - matrix_all => JSON array of {version, push_mode} objects for ALL versions.
//   Used by push-containers.yaml to select the make target (push vs push_multi).
// - matrix_multi => same but filtered to multi-arch versions only (currently unused,
//   reserved for future use if ARM builds are separated from push_multi).

// Every maistra-builder version we know about.
// Each one corresponds to a Dockerfile: `docker/maistra-builder_<version>.Dockerfile`
// 2.2 excluded: CentOS Stream 8 EOL, mirrors dead, Prow never had jobs for it.
// 2.3, 2.4 included but unbuildable for the same reason (Prow had jobs).
const ALL_VERSIONS = ['2.3', '2.4', '2.5', '2.6', '3.0', '3.1', '3.2', '3.3', '3.4', '3.5', 'main'];

// Versions that only produce x86 images
const SINGLE_ARCH_VERSIONS = ['2.3', '2.4'];

// File path patterns that affect ALL versions.
// Makefile defines how every image is built.
// docker/scripts/ contains shared scripts used by all Dockerfiles.
const SHARED_PATHS = [
  /^docker\/scripts\//,
  /^Makefile$/
];

// Extract the version string from a Dockerfile path.
// e.g. 'docker/maistra-builder_3.5.Dockerfile' -> '3.5'
const VERSION_REGEX = /^docker\/maistra-builder_(.+)\.Dockerfile$/;

// Takes a list of version strings and returns two arrays of objects:
// - all: every version, each tagged with push_mode ( 'single' or 'multi')
// - multi: only the versions that need ARM builds and multi-arch manifests
//
// Example: classifyVersions(['2.3', '3.5', 'main']) returns:
//   all:   [{version:'2.3', push_mode:'single'}, {version:'3.5', push_mode:'multi'}, {version:'main', push_mode:'multi'}]
//   multi: [{version:'3.5', push_mode:'multi'}, {version:'main', push_mode:'multi'}]
function classifyVersions(versionList) {
    const all = versionList.map(v => ({
        version: v,
        push_mode: SINGLE_ARCH_VERSIONS.includes(v) ? 'single' : 'multi'
    }));

    const multi = all.filter(v => v.push_mode === 'multi');
    return { all, multi };
}

// Given a list of changed files returns which versions need rebuilding.
//
// Returns null if no build-relevant files changed -> nothing to do.
// Returns ALL_VERSIONS if ANY shared file changed, because shared files affect all versions.
// Return only specific versions whose Dockerfiles changed otherwise.
function extractVersions(files) {
    const filenames = files.map(f => f.filename);

    // Check if any shared file changed. If so, rebuild everything
    const hasSharedChange = filenames.some(name => SHARED_PATHS.some(re => re.test(name)));
    if (hasSharedChange) return ALL_VERSIONS;

    // Check if any version-specific Dockerfile changed.
    // Extract the version string from each matching Dockerfile path
    const versions = filenames
        .map(name => {
            const m = name.match(VERSION_REGEX);
            return m ? m[1] : null;
        })
        .filter(v => v !== null);
    
    // No build-relevant files changed at all
    if (versions.length === 0) return null;

    // Set() removes duplicates ( just in case )
    return [...new Set(versions)];

}


// Main entry point. Called from GHA workflows via actions/github-script.
// See parameter docs at the top of this file.
module.exports = async function detect({ github, context, core, mode, prNumber, version }) {
    let versionList;

    if (mode === 'manual' && version) {
        if (!ALL_VERSIONS.includes(version)) {
            core.warning(`Version '${version}' is not in ALL_VERSIONS. Build may fail.`);
        }
        versionList = [version];
    } else if (mode === 'pr') {
        // PR mode: fetch the list of files changed in the PR from Github API
        //          then extract which versions are affected.
        const files = await github.paginate(github.rest.pulls.listFiles, {
            owner: context.repo.owner,
            repo: context.repo.repo,
            pull_number: prNumber,
            per_page: 100
        });
        versionList = extractVersions(files);
    } else if (mode === 'push') {
        // Push mode: compare the before and after commits of the push event
        //            to find which files changed, then extract affected versions.
        const compare = await github.rest.repos.compareCommitsWithBasehead({
            owner: context.repo.owner,
            repo: context.repo.repo,
            basehead: `${context.payload.before}...${context.payload.after}`
        });
        versionList = extractVersions(compare.data.files || []);
    } else {
        core.setFailed(`Unknown mode: ${mode}`);
        return;
    }

    // If no build-relevant files changed, set all outputs to empty/false and exit
    if (!versionList) {
        core.info('No build-relevant files changed, skipping');
        core.setOutput('needs_build', 'false');
        core.setOutput('versions', '[]');
        core.setOutput('matrix_all', '[]');
        core.setOutput('matrix_multi', '[]');
        return;
    }

    // Build two matrices and set outputs
    const { all, multi } = classifyVersions(versionList);
    core.setOutput('needs_build', 'true');
    core.setOutput('versions', JSON.stringify(versionList));
    core.setOutput('matrix_all', JSON.stringify(all));
    core.setOutput('matrix_multi', JSON.stringify(multi));
    core.info(`Versions: ${versionList.join(', ')}`);
    core.info(`Multi-arch: ${multi.map(v => v.version).join(', ') || 'none'}`);

};