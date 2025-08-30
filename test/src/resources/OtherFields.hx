package src.resources;

package examples.config;

class OtherFields {

    var someField: String;
    var someOtherField: Int;

    @:data var _data = {
                        endpoints: [
                            {
                                name: "api",
                                url: "https://api.example.com"
                            },
                            {
                                name: "cdn",
                                url: "https://cdn.example.com"
                            }
                        ],
                        features: {
                            analytics: true,
                            experimental: [
                                "fast-path",
                                "edge-cache"
                            ],
                            payments: true
                        },
                        limits: {
                            maxUsers: 10000,
                            timeouts: {
                                connectMs: 3000,
                                readMs: 10000
                            }
                        },
                        version: "1.4.2"
                    };

        public function doStuff(): Int {
            var a = 1;
            var b = 2;
            var c = a + b;
            return c;
        }

}
