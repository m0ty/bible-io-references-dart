/// Broad sanity limits shared by references and custom versification data.
///
/// These deliberately exceed every chapter and verse number in the bundled
/// canon. They reject pathological numeric input without claiming that a
/// particular verse exists in a specific translation.
const int maxReferenceChapterNumber = 999;

/// The largest verse number representable by this package's reference model.
const int maxReferenceVerseNumber = 999;
