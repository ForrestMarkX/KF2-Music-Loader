class KFMusicTrackInfo_Custom extends KFMusicTrackInfo;

var() AkBaseSoundObject StandardSong;
var() AkBaseSoundObject InstrumentalSong;
var() bool bIsAkEvent;
var() float FadeInTime;

defaultproperties
{
	FadeInTime=5.f
	bIsAkEvent=false
}