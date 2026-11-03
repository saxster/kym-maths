// KymMaths' tutor profile for the shared KymTutorAI constitution (teaching_kit).
// KymMaths ran a byte-identical copy of the tutor's constitution, so its profile is the generic
// wording with its own app name (shown in the parent safety notification) and subject label.
// Registered in KymMathsApp.init.

extension TutorSubjectProfile {
    static let kymMaths: TutorSubjectProfile = {
        var profile = TutorSubjectProfile.generic
        profile.appName = "KymMaths"
        profile.subjectLabel = "mathematics"
        return profile
    }()
}
