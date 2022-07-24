package steamworks;

@:keep
@:unreflective
@:buildXml('
    <files id="steamworks">
        <include name="D:\\programming\\haxe\\hxcpp_luv\\src\\cpp\\luv\\luv.xml"/>

        <compilerflag value="-IC:\\Users\\AidanLee\\Desktop\\mnc_bot\\src\\steamworks"/>
        <compilerflag value="-IC:\\Users\\AidanLee\\Desktop\\mnc_bot\\libs\\steamworks\\include"/>
        <file name="C:\\Users\\AidanLee\\Desktop\\mnc_bot\\src\\steamworks\\Steamworks.cpp"/>
    </files>

    <files id="haxe">
        <compilerflag value="-IC:\\Users\\AidanLee\\Desktop\\mnc_bot\\src\\steamworks"/>
        <compilerflag value="-IC:\\Users\\AidanLee\\Desktop\\mnc_bot\\libs\\steamworks\\include"/>
    </files>

    <target id="haxe">
        <files id="steamworks"/>

        <lib name="C:\\Users\\AidanLee\\Desktop\\mnc_bot\\libs\\steamworks\\lib\\steam_api64.lib"/>
        <lib name="C:\\Users\\AidanLee\\Desktop\\mnc_bot\\libs\\steamworks\\lib\\sdkencryptedappticket64.lib"/>
    </target>
')
@:include('steamworks.hpp')
extern class Steamworks
{
    @:native('steamworks::init')
    static function init() : Bool;

    @:native('steamworks::pump')
    static function pump() : Void;

    @:native('steamworks::shutdown')
    static function shutdown() : Void;
}