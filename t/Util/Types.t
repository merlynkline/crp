use Test::More;
use Test::Exception;

use CRP::Util::Types 'type_check';

lives_ok  { type_check({MaxLen => 3}, undef)   } 'MaxLen with undef';
lives_ok  { type_check({MaxLen => 3}, 'xx')    } 'MaxLen with short string';
throws_ok { type_check({MaxLen => 3}, 'xxxx')  } qr{^CRP::Util::Types::MaxLen}, 'MaxLen with long string';
throws_ok { type_check({MaxLen => 3}, \'xxxx') } qr{^CRP::Util::Types::_NotScalar}, 'MaxLen with ref';

throws_ok { type_check({MinLen => 3}, undef)   } qr{^CRP::Util::Types::MinLen}, 'MinLen with undef';
lives_ok  { type_check({MinLen => 3}, 'xxxx')  } 'MinLen with long string';
throws_ok { type_check({MinLen => 3}, 'xx')    } qr{^CRP::Util::Types::MinLen}, 'MinLen with short string';
throws_ok { type_check({MinLen => 3}, \'xxxx') } qr{^CRP::Util::Types::_NotScalar}, 'MinLen with ref';

done_testing();
