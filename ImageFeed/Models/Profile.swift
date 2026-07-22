import Foundation

struct ProfileResult: Decodable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?

    init(username: String, name: String, loginName: String, bio: String?) {
        self.username = username
        self.name = name
        self.loginName = loginName
        self.bio = bio
    }

    init(from profileResult: ProfileResult) {
        username = profileResult.username

        let firstName = profileResult.firstName ?? ""
        let lastName = profileResult.lastName ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        name = fullName.isEmpty ? profileResult.username : fullName

        loginName = "@\(profileResult.username)"
        bio = profileResult.bio
    }
}
