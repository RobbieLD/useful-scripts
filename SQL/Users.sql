-- Make User
use master
go

create login BatchLogin with password = 'password';
go

use [my-database]
go

create user BatchUser for login BatchLogin;
go

grant select, insert, connect on MyTable to BatchUser;
go

ALTER USER BatchUser WITH DEFAULT_SCHEMA = dbo
go


-- Remove User
use [my-database]
go

drop user BatchUser;
go

use master
go

drop login BatchLogin;
go

