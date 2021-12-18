# MSvsPG_nosql_benchmark

Benchmark jest w postaci skryptu pg_nosql_benchmark, wykorzystuje funkcje z lib/
Adaptacja orygnialnego benchmarku ma polegać na zmianie skryptów tak, aby wykonały one benchmark na serwerze MSSQL, a nie mongoDB.

Należy postawić serwer postgreSQL oraz MSSQL i skonfigurować następująco:
UWAGA : dostęp do ról typu superuser powinien odbywać się wyłącznie przy użyciu praw administratora systemu, w produkcji nie powinno się ustawiać hasła do tych ról, tutaj to ignorujemy.

postgreSQL
1. ustawić w skrypcie ścieżki PGHOME oraz PGBIN
2. serwer na localhost(127.0.0.1) port=5432 (tak chyba jest domyślnie)
3. nazwa użytkownika = 'postgres', hasło = 'admin' https://stackoverflow.com/questions/1471571/how-to-configure-postgresql-for-the-first-time
4. stworzona baza 'benchmark' (lub zostanie automatycznie utworzona przy pierwszym uruchomieniu skryptu, chyba)

MSSQL
1. ustawić w skrypcie ścieżkę MSSQL do klienta sqlcmd (!sqlcmd jest w oddzielnym pakiecie od mssql-server!)
2. serwer na localhost(127.0.0.1) port=27017 (chyba domyślnie)
3. nazwa użytkownika = 'SA', hasło = 'Admin1234' (SuperAdmin, domyślna rola, hasło podawane przy konfiguracji)
4. stworzona baza 'benchmark' (lub zostanie automatycznie utworzona przy pierwszym uruchomieniu skryptu, chyba)
