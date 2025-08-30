package examples.data;

class UserProfile extends BaseModel implements ISerializable, IValidatable {

    @:data var _data = {
                        active: true,
                        email: "alice@example.com",
                        id: 12345,
                        meta: null,
                        name: "Alice Smith",
                        profile: {
                            address: {
                                city: "Metropolis",
                                street: "123 Main St",
                                zip: "10101"
                            },
                            preferences: {
                                languages: [
                                    "en",
                                    "es"
                                ],
                                notifications: {
                                    email: true,
                                    sms: false
                                },
                                theme: "dark"
                            }
                        },
                        sessions: [
                            {
                                device: "web",
                                lastActive: "2025-08-30T12:00:00Z"
                            },
                            {
                                device: "mobile",
                                lastActive: "2025-08-29T08:15:00Z"
                            }
                        ],
                        tags: [
                            "admin",
                            "beta",
                            "🚀"
                        ]
                    };

}
