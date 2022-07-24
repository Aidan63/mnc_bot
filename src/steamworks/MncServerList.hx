package steamworks;

@:keep
@:native('steamworks::MncServerList')
@:include('steamworks.hpp')
@:unreflective
extern class MncServerList
{
    @:native('steamworks::MncServerList::Create')
    static function create(_response : (_index : Int, _players : Int, _maxPlayers : Int, _name : String, _tags : String)->Void, _failed : Int->Void, _refreshed : Int->Void) : cpp.Pointer<MncServerList>;

    @:native('Refresh')
    function refresh() : Void;
}