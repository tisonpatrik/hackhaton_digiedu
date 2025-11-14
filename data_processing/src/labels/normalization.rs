/// Normalize a label name for comparison
/// - Convert to lowercase
/// - Remove special characters except underscores
/// - Trim whitespace
/// - Replace multiple spaces/underscores with single underscore
pub fn normalize_label(label: &str) -> String {
    label
        .to_lowercase()
        .chars()
        .map(|c| {
            if c.is_alphanumeric() || c == '_' || c == ' ' {
                c
            } else {
                '_'
            }
        })
        .collect::<String>()
        .split_whitespace()
        .collect::<Vec<&str>>()
        .join("_")
        .split('_')
        .filter(|s| !s.is_empty())
        .collect::<Vec<&str>>()
        .join("_")
}

/// Calculate Levenshtein distance between two strings
fn levenshtein_distance(s1: &str, s2: &str) -> usize {
    let len1 = s1.chars().count();
    let len2 = s2.chars().count();
    
    if len1 == 0 {
        return len2;
    }
    if len2 == 0 {
        return len1;
    }
    
    let mut matrix = vec![vec![0; len2 + 1]; len1 + 1];
    
    for i in 0..=len1 {
        matrix[i][0] = i;
    }
    for j in 0..=len2 {
        matrix[0][j] = j;
    }
    
    let s1_chars: Vec<char> = s1.chars().collect();
    let s2_chars: Vec<char> = s2.chars().collect();
    
    for i in 1..=len1 {
        for j in 1..=len2 {
            let cost = if s1_chars[i - 1] == s2_chars[j - 1] { 0 } else { 1 };
            matrix[i][j] = std::cmp::min(
                std::cmp::min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1        // insertion
                ),
                matrix[i - 1][j - 1] + cost    // substitution
            );
        }
    }
    
    matrix[len1][len2]
}

/// Calculate similarity ratio between two strings (0.0 to 1.0)
/// Uses normalized Levenshtein distance
pub fn calculate_similarity(s1: &str, s2: &str) -> f64 {
    if s1 == s2 {
        return 1.0;
    }
    
    let distance = levenshtein_distance(s1, s2);
    let max_len = std::cmp::max(s1.len(), s2.len());
    
    if max_len == 0 {
        return 1.0;
    }
    
    1.0 - (distance as f64 / max_len as f64)
}

/// Find a similar label from a list of existing labels
/// Returns Some((label_name, normalized_name, similarity)) if a similar label is found
/// Similarity threshold is 0.85 (85% similar)
pub fn find_similar_label(
    new_label: &str,
    existing_labels: &[(String, String)], // (name, normalized_name)
) -> Option<(String, String, f64)> {
    let normalized_new = normalize_label(new_label);
    const SIMILARITY_THRESHOLD: f64 = 0.85;
    
    let mut best_match: Option<(String, String, f64)> = None;
    let mut best_similarity = 0.0;
    
    for (name, normalized) in existing_labels {
        // Exact match on normalized name
        if normalized == &normalized_new {
            return Some((name.clone(), normalized.clone(), 1.0));
        }
        
        // Calculate similarity
        let similarity = calculate_similarity(&normalized_new, normalized);
        
        if similarity >= SIMILARITY_THRESHOLD && similarity > best_similarity {
            best_similarity = similarity;
            best_match = Some((name.clone(), normalized.clone(), similarity));
        }
    }
    
    // Also check for singular/plural variants
    if best_match.is_none() {
        for (name, normalized) in existing_labels {
            // Check if one is plural of the other
            let is_plural_variant = 
                (normalized_new.ends_with('s') && normalized == &normalized_new[..normalized_new.len()-1]) ||
                (normalized.ends_with('s') && &normalized_new == &normalized[..normalized.len()-1]);
            
            if is_plural_variant {
                return Some((name.clone(), normalized.clone(), 0.95));
            }
        }
    }
    
    best_match
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_normalize_label() {
        assert_eq!(normalize_label("Teaching Methods"), "teaching_methods");
        assert_eq!(normalize_label("Student-Engagement"), "student_engagement");
        assert_eq!(normalize_label("  Multiple   Spaces  "), "multiple_spaces");
        assert_eq!(normalize_label("Special!@#Characters"), "special_characters");
    }
    
    #[test]
    fn test_calculate_similarity() {
        assert_eq!(calculate_similarity("hello", "hello"), 1.0);
        assert!(calculate_similarity("hello", "hallo") > 0.8);
        assert!(calculate_similarity("teaching", "teacher") > 0.7);
        assert!(calculate_similarity("abc", "xyz") < 0.5);
    }
    
    #[test]
    fn test_find_similar_label() {
        let existing = vec![
            ("teaching_methods".to_string(), "teaching_methods".to_string()),
            ("student_engagement".to_string(), "student_engagement".to_string()),
        ];
        
        // Exact match
        let result = find_similar_label("teaching_methods", &existing);
        assert!(result.is_some());
        assert_eq!(result.unwrap().2, 1.0);
        
        // Similar match
        let result = find_similar_label("teaching_method", &existing);
        assert!(result.is_some());
        
        // Not similar
        let result = find_similar_label("completely_different", &existing);
        assert!(result.is_none() || result.unwrap().2 < 0.85);
    }
}
