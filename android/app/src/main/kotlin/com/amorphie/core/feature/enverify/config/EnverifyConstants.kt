package com.amorphie.core.feature.enverify.config

object EnverifyConstants {

    const val v_55 = "demo"  //aiUsername
    const val v_56 = "idverify" //aiPassword
    const val v_57 = "turnuser"   //turn username
    const val v_58 = "12345"  //turn password

    //prep-test env.
    const val v_50 = "test-enverify-aiweb.burgan.com.tr"  //domain
    const val v_52 = "turn:test-enverify-turnstun.ebt.bank:3478" //turn name
    const val v_53 = "stun:test-enverify-turnstun.ebt.bank:3478"  //stun name
    const val v_54 = "test-enverify-signaling.burgan.com.tr"  //signaling
    const val v_54ms = "test-enverify-signaling-ms.burgan.com.tr"  //signalMediaServer
    const val v_59 = "https://test-enverify-mapip.burgan.com.tr"  //backofficeBase

    //preprod env.
    const val v_60 = "preprod-enverify-aiweb.burgan.com.tr"
    const val v_62 = "turn:preprod-enverify-turnstun.burgan.com.tr"
    const val v_63 = "stun:preprod-enverify-turnstun.burgan.com.tr"
    const val v_65 = "preprod-enverify-signaling.burgan.com.tr"
    const val v_65ms = "preprod-enverify-signaling-ms.burgan.com.tr"
    const val v_66 = "https://preprod-enverify-mapip.burgan.com.tr"

    //pilot env.
    const val v_90 = "pilot-enverify-aiweb.burgan.com.tr"
    const val v_92 = "turn:pilot-enverify-turnstun.burgan.com.tr"
    const val v_93 = "stun:pilot-enverify-turnstun.burgan.com.tr"
    const val v_95 = "pilot-enverify-signaling.burgan.com.tr"
    const val v_95ms = "pilot-enverify-signaling-ms.burgan.com.tr"
    const val v_96 = "https://pilot-enverify-mapip.burgan.com.tr"

    //prod
    const val v_67 = "enverify-aiweb.burgan.com.tr" //domain
    const val v_69 = "turn:enverify-turnstun.burgan.com.tr:3478" //turnNamePort
    const val v_70 = "stun:enverify-turnstun.burgan.com.tr:3478" //stunNamePort
    const val v_71 = "enverify-signaling.burgan.com.tr" //signalServer
    const val v_71ms = "enverify-signaling-ms.burgan.com.tr" //signalMediaServer
    const val v_72 = "demo" //credentialName
    const val v_73 = "idverify" //credentialPassword
    const val v_74 = "turnuser" //turnUsername
    const val v_75 = "efm483bmr785" //turnPassword
    const val v_76 = "https://enverify-mapip.burgan.com.tr" //backOfficeBaseURL
    const val v_700 = "12345678901234567890" //

    const val v_04t024 = "-----BEGIN CERTIFICATE-----\n" +
            "MIIGljCCBX6gAwIBAgIMW5ZrfLjW+nbubjnVMA0GCSqGSIb3DQEBCwUAMFAxCzAJ\n" +
            "BgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSYwJAYDVQQDEx1H\n" +
            "bG9iYWxTaWduIFJTQSBPViBTU0wgQ0EgMjAxODAeFw0yMzAzMDcxMDQ5MThaFw0y\n" +
            "NDA0MDcxMDQ5MTdaMGkxCzAJBgNVBAYTAlRSMRIwEAYDVQQIDAnEsFNUQU5CVUwx\n" +
            "EDAOBgNVBAcTB1NBUklZRVIxGjAYBgNVBAoMEUJVUkdBTiBCQU5LIEEuxZ4uMRgw\n" +
            "FgYDVQQDDA8qLmJ1cmdhbi5jb20udHIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw\n" +
            "ggEKAoIBAQDvUbekIX6O95vN21hcF2kJmPD2giKGUOrez7Ps+jrclFr/yzsqS3y5\n" +
            "1IFwUeLuuL8P9haBWTIgdNDKaPE0JskH5IPsVExC5BrWurDmk5c96pYN/yQ32m45\n" +
            "a1qoqIXwQzQi3oBlB3ISvsCXmGLqpOhnF8Gzq3hCNnmEiyl69oBnPUfkSFakPakg\n" +
            "WZe2nDCPK3+idBcGtfa3YMxTqFl/VRkUTrsjQFxFRg0ZyoqDxvcLFGQ9igXQ/b+O\n" +
            "0X7BWnYgt39aBhyikFVbF2kw+iSWbXXCHn8In+MiRUN+OCEx7GF1hzP/pYQ+HZhz\n" +
            "/l4FYWDuYSJ3pcr3/1z24LpX34V0tBzFAgMBAAGjggNVMIIDUTAOBgNVHQ8BAf8E\n" +
            "BAMCBaAwgY4GCCsGAQUFBwEBBIGBMH8wRAYIKwYBBQUHMAKGOGh0dHA6Ly9zZWN1\n" +
            "cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dzcnNhb3Zzc2xjYTIwMTguY3J0MDcG\n" +
            "CCsGAQUFBzABhitodHRwOi8vb2NzcC5nbG9iYWxzaWduLmNvbS9nc3JzYW92c3Ns\n" +
            "Y2EyMDE4MFYGA1UdIARPME0wQQYJKwYBBAGgMgEUMDQwMgYIKwYBBQUHAgEWJmh0\n" +
            "dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAgGBmeBDAECAjAJ\n" +
            "BgNVHRMEAjAAMD8GA1UdHwQ4MDYwNKAyoDCGLmh0dHA6Ly9jcmwuZ2xvYmFsc2ln\n" +
            "bi5jb20vZ3Nyc2FvdnNzbGNhMjAxOC5jcmwwKQYDVR0RBCIwIIIPKi5idXJnYW4u\n" +
            "Y29tLnRygg1idXJnYW4uY29tLnRyMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEF\n" +
            "BQcDAjAfBgNVHSMEGDAWgBT473/yzXhnqN5vjySNiPGHAwKz6zAdBgNVHQ4EFgQU\n" +
            "p7mClxOunTKZeYAd0YqSWygEzjMwggF+BgorBgEEAdZ5AgQCBIIBbgSCAWoBaAB2\n" +
            "AO7N0GTV2xrOxVy3nbTNE6Iyh0Z8vOzew1FIWUZxH7WbAAABhruwuUcAAAQDAEcw\n" +
            "RQIhAKA4QWCVOon22bMM3PfznvYsR5r+QWAMmvwYQbrAH2EgAiBoTCxNbr8nnXj7\n" +
            "lQr8mtLZNpuj+d3C3jJPBQVN1/atpAB1AHb/iD8KtvuVUcJhzPWHujS0pM27Kdxo\n" +
            "Qgqf5mdMWjp0AAABhruwuYoAAAQDAEYwRAIgVnMPWARB9hBHWubUf2FMezZmJfHF\n" +
            "cQBHDgK5zS319HoCIHWxiq2sPOz9jZWoFpyFs1RspFJqMq7BDpoogsoSrlNLAHcA\n" +
            "2ra/az+1tiKfm8K7XGvocJFxbLtRhIU0vaQ9MEjX+6sAAAGGu7C5iQAABAMASDBG\n" +
            "AiEAsoBAxafO3aMeEzXSrEi64ri6Pdp7y+BTps136NeKyjACIQCDrN9F+QHRNXhs\n" +
            "l3vsjUivsmZTYkePiQLcd0vU5lJ0BzANBgkqhkiG9w0BAQsFAAOCAQEAOZxDJev5\n" +
            "qHYX2HqP2o9v9x4cDZzWnvic2S55jZCPwgF5dvzyOQzaZSzyWBxDXVYFOJ/Rkjt+\n" +
            "G3DX261YoHqUiDLMkYn9ciUNm8eiZ+imvYncAi/W6WUQTil57V3swOH4ctLXu+m6\n" +
            "Cgkm21UOWnPHeUW6noWEA54CeJUzjqzRJlbffF+32brxO4zdjf6G5yKQtjU/2WcK\n" +
            "tALYyzuhyaU/9ymDcNkUFiQKy5uMnxb8HHkEJETTtta1RUScuQ2AZZ+t9/Q0L2cR\n" +
            "fN+wiDJnXpRBQwn+AByfK8RMDjsE9ye0V0bmEhJfmzvZX56sp9rZHL9VpfIGABBC\n" +
            "Mwm28x+gkDMKYQ==\n" +
            "-----END CERTIFICATE-----"
}