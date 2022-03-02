-- Make User
use master
go

create login BatchLogin with password = 'password';
go

use [dev-stratos-youi-rates-dev]
go

create user BatchUser for login BatchLogin;
go

grant select, insert on RatingFactorsAddressRating to BatchUser;
go

-- Remove User
use [dev-stratos-youi-rates-dev]
go

drop user BatchUser;
go

use master
go

drop login BatchLogin;
go

