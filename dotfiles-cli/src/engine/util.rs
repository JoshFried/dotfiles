use std::path::Path;

pub(super) fn paths_equivalent(left: &Path, right: &Path) -> bool {
    match (left.canonicalize(), right.canonicalize()) {
        (Ok(left), Ok(right)) => left == right,
        _ => left == right,
    }
}

pub(super) fn normalize_git_url(url: &str) -> String {
    url.trim()
        .trim_end_matches(".git")
        .replace("git@github.com:", "https://github.com/")
        .replace("ssh://git@github.com/", "https://github.com/")
}

pub(super) fn package_token(name: &str) -> &str {
    name.rsplit('/').next().unwrap_or(name)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn package_tokens_strip_tap_names() {
        assert_eq!(
            package_token("FelixKratz/formulae/sketchybar"),
            "sketchybar"
        );
        assert_eq!(package_token("ripgrep"), "ripgrep");
    }

    #[test]
    fn git_urls_are_normalized_across_transports() {
        assert_eq!(
            normalize_git_url("git@github.com:owner/repo.git"),
            "https://github.com/owner/repo"
        );
        assert_eq!(
            normalize_git_url("ssh://git@github.com/owner/repo"),
            "https://github.com/owner/repo"
        );
    }
}
