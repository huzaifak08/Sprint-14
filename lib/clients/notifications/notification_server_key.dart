import 'dart:developer' as dev;
import 'package:googleapis_auth/auth_io.dart';

class NotificationServerKey {
  Future<String> getServerKeyToken() async {
    final scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "sprint14-d3ab2",
        "private_key_id": "86171c34e4b5c9a7a1957e0d8d8d4ddfe441526c",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC5XYvGT4gOddIB\nElPybZoMKR3xEBzY9eawDkFGpRwIil5Srsa8Cn1ndUDaPGO96NkmauUAPFixsLP+\nEqC+OW33rsfJ7iAiYnmslI2y5S8bE50FOcvpag/jpO8Iu3VfOoPVDVNqHmjaix2f\n9XI2Qt25sUNAo+enlstvGGJXzGkdLi7NgbVagqsUa0cq/IctZ0D6op7sNBpWGpKt\ngOY8pedqfg4l8InKA8ypWIabVmZtLk7i1iE5JESNWvRQ0WvuGVzKo/qmOBstv3P4\nD6K1sf3FeKeP48TYnejap7k6ClJrGo2ppSXwWbWqR4axfWFxIvS6DmnkFB0qbxxk\nennxEw4/AgMBAAECggEABObRXGQb/+3jqL2YVK/LRAkOTqKTcLVH7V3jIgAZtqwa\nBGu0u6I3YLX8CglQxePTYi2vcosl+UTn7Y8GiyEvpD4N8GwIk4AxIXwoJxPiY//n\nxgyaNMjmNKnW3E9Askz00XxxuTumoCjPlrxB0eeAv3lNgvcSmB7nsD9f0lyIZwoW\n9/HVDxGi2trVC/5ux7XAyYb8LdSogX4gOpqNxrTzKR/m+6CrpKztXtFeS3wpX+bw\nvxYwNes8qXSbXglmTn8rKpw/ZvVGXgBw7t4safSbw1csSv4FUH+D8nMjYig+BN2/\n66amqP9o7BKg6fKQGelGX6YxbZLNuqI5Iw+GgMkWMQKBgQD5qzcFO/V/MHcYAwlV\n+lMzIC+sMTQdcCgCcQrHWebrzXFYJciHLqxZ2WH3EWBGfmoBmSswk9NnFRQOuGx4\n1KCg8SXLoh/MgAgX9LTs14eBmfpgXeKpOFMIAonDN83lwVVrniF3CAhsoouvkbSH\nk7KV1i1Kslv9E1OkH8mQ+rMI6QKBgQC+EOPfszQba8Fh/2dVhIqZtBNEviBJ/HSZ\nSX4wbQ2XATHrsVMayCoXaTAntoFyNCYlGo3xXlgEg3bI16c5ua2q5PQ17bBpYAsg\nb54tWtbE2ySEn2tGF9LdAjRwbPIYTHHZmkag7QjEKHJHAuiakgu7FD+BBRLH++8K\nLKmWotNk5wKBgQCP8vGkKO/gx3bC9204jz3NKm+SHkRn/LR0w+xtCB6mMit5oT8/\nAeAJZdaf9vrFajmAdml6dqDavEJ2Qkr4V8/NO3yJLg6bf+4qscJnE9VjGf5L9ZWr\n73egFKaNUe163L99bwzobk89I3LaZW3rBXNgBL7UZIW5Ip2E8XbsCj+TkQKBgGnW\nYe4ZjjSOxnrZjCM00TFR80DeVoCckhkhsaEpuN2TjsbeUZaiS74JlwUmPeLoYy1a\nIhx8Gqs4wZaJb9dXK/vzzoGRQCENmGSRgxVidiHcnfM0CrpXXdYv+h94qz8YonU3\n0YifNbh1hV1Bo2EfXmTom4wu1QyDn9KcmDsHpIuVAoGAMksjk4RYEHNp4bXqr9Di\nHYsLEa282NwOn30Lk5LBK9Jb19NtPp0LoQmNjtzfCk9wpPJ7/pPqjgQMl28qgGB4\nqVnfRml8w0icaFdF578evOzi/pjInEd0nnmNDdK4gdTA8Kef5uFcaZ5irQ/MASTJ\n1HWHP99YB8aoAQDwCenaYXs=\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-fbsvc@sprint14-d3ab2.iam.gserviceaccount.com",
        "client_id": "117556256175956034402",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40sprint14-d3ab2.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com",
      }),
      scopes,
    );

    final accessServerKey = client.credentials.accessToken.data;
    dev.log("ACCESS TOKEN => $accessServerKey");

    return accessServerKey;
  }
}
