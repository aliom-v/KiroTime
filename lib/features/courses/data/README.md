# Course Data Model

`CourseMeta` stores stable course metadata.

`CourseSchedule` stores one concrete time/place occurrence for a course.

The public `id` fields are strings because import, sync, and export flows should not depend on Isar's internal integer key. The Isar `isarId` getter derives a stable integer key from the string id.

`CourseSchedule.weeks` is intentionally an explicit `List<int>`. Do not replace it with an odd/even flag; that loses skipped-week and custom-week information.
