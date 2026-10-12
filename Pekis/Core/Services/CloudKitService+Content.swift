import Foundation
import CloudKit
import Combine
import OSLog

// Love notes, This or That answers, and daily moments. Every record lives in the shared couple zone.
@MainActor
extension CloudKitService {
    // MARK: - Love Notes

    func sendLoveNote(content: String) async throws {
        guard let couple = couple, let userID = currentUserID else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let note = LoveNote(
            coupleID: couple.id,
            authorID: userID,
            content: content
        )

        // Use the fetched couple record's actual zone (it carries the correct ownerName
        // for Partner B, who lives in the sharedDatabase). Both partners write to the same
        // zone: Partner A via privateDatabase, Partner B via sharedDatabase.
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let record = note.toRecord(in: zoneID)
        let database = databaseContaining(zoneID)

        do {
            _ = try await withRetry { try await database.save(record) }
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func fetchLoveNotes() async throws -> [LoveNote] {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let predicate = NSPredicate(format: "coupleID == %@", couple.id)
        let query = CKQuery(recordType: LoveNote.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        // Must specify inZoneWith, because records(matching:) without a zone only
        // searches the DEFAULT zone, not our custom CoupleZone. Also route to the
        // correct database (private for Partner A, shared for Partner B). All records
        // for both partners live in Partner A's zone, so one database fetch is enough.
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = databaseContaining(zoneID)

        do {
            var notes: [LoveNote] = []

            let results = try await withRetry { try await database.records(matching: query, inZoneWith: zoneID) }
            for (_, result) in results.matchResults {
                if case .success(let record) = result,
                   let note = LoveNote(record: record) {
                    notes.append(note)
                }
            }

            notes.sort { $0.createdAt > $1.createdAt }
            LoveNote.saveToCache(notes)
            return notes
        } catch {
            let cached = LoveNote.loadFromCache()
            if !cached.isEmpty {
                return cached
            }
            throw CloudKitError.fetchFailed(error)
        }
    }

    // MARK: - This or That

    func saveThisOrThatAnswer(questionIndex: Int, selectedOption: Int) async throws {
        guard let couple = couple, let userID = currentUserID else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let answer = ThisOrThatAnswer(
            coupleID: couple.id,
            authorID: userID,
            questionIndex: questionIndex,
            selectedOption: selectedOption
        )

        // Same zone routing as sendLoveNote.
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let record = answer.toRecord(in: zoneID)
        let database = databaseContaining(zoneID)

        do {
            _ = try await withRetry { try await database.save(record) }
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func fetchThisOrThatAnswers() async throws -> [ThisOrThatAnswer] {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let predicate = NSPredicate(format: "coupleID == %@", couple.id)
        let query = CKQuery(recordType: ThisOrThatAnswer.recordType, predicate: predicate)

        // Same zone + database routing as fetchLoveNotes.
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = databaseContaining(zoneID)

        do {
            var answers: [ThisOrThatAnswer] = []

            let results = try await withRetry { try await database.records(matching: query, inZoneWith: zoneID) }
            for (_, result) in results.matchResults {
                if case .success(let record) = result,
                   let answer = ThisOrThatAnswer(record: record) {
                    answers.append(answer)
                }
            }

            ThisOrThatAnswer.saveToCache(answers)
            return answers
        } catch {
            let cached = ThisOrThatAnswer.loadFromCache()
            if !cached.isEmpty {
                return cached
            }
            throw CloudKitError.fetchFailed(error)
        }
    }

    // MARK: - Moments

    func saveMoment(imageData: Data, prompt: String) async throws {
        guard let couple = couple, let userID = currentUserID else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let moment = MomentShareRecord(
            coupleID: couple.id,
            authorID: userID,
            prompt: prompt
        )

        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let record = moment.toRecord(in: zoneID)

        // Write JPEG data to a temp file, since CKAsset requires a file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(moment.id + ".jpg")
        do {
            try imageData.write(to: tempURL)
        } catch {
            throw CloudKitError.saveFailed(error)
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }

        record[MomentShareRecord.RecordKey.photo.rawValue] = CKAsset(fileURL: tempURL)

        let database = databaseContaining(zoneID)

        do {
            _ = try await withRetry { try await database.save(record) }
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func fetchTodaysMoments() async throws -> [MomentShareRecord] {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = NSPredicate(
            format: "coupleID == %@ AND createdAt >= %@",
            couple.id,
            startOfDay as NSDate
        )
        let query = CKQuery(recordType: MomentShareRecord.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = databaseContaining(zoneID)

        do {
            var moments: [MomentShareRecord] = []
            let results = try await withRetry { try await database.records(matching: query, inZoneWith: zoneID) }
            for (_, result) in results.matchResults {
                if case .success(let record) = result,
                   let moment = MomentShareRecord(record: record) {
                    moments.append(moment)
                }
            }
            return moments
        } catch {
            throw CloudKitError.fetchFailed(error)
        }
    }
}
