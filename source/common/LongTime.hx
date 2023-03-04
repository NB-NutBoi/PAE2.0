package common;

import utility.Utils;

typedef LongTimeCache = {
    public var counting:Bool;

    public var seconds:Float;
    public var minutes:Int;
    public var hours:Int;
    public var days:Int;
    public var years:Int;
}

class LongTime {

    public static var times:Array<LongTime> = [];

    public static function update(elapsed:Float) {
        for (time in times) {
            if(!time.counting) continue;
            time.seconds += elapsed;
            time.updateTime();
        }
    }
    
    public var seconds:Float = 0;
    public var minutes:Int = 0;
    public var hours:Int = 0;
    public var days:Int = 0;
    public var years:Int = 0;

    public var counting:Bool = false;

    public function new(?cache:LongTimeCache = null) {
        if(cache != null) setCache(cache);
        times.push(this);
    }

    public function setCache(cache:LongTimeCache) {
        seconds = cache.seconds;
        minutes = cache.minutes;
        hours = cache.hours;
        days = cache.days;
        years = cache.years;

        counting = cache.counting;
    }

    public function getCache():LongTimeCache {
        return {
            counting: counting,

            seconds: seconds,
            minutes: minutes,
            hours: hours,
            days: days,
            years: years
        };
    }

    public function updateTime() {
        while(seconds >= 60){
            seconds -= 60;
            minutes++;
        }

        while(minutes >= 60){
            minutes -= 60;
            hours++;
        }

        while(hours >= 24){
            hours -= 24;
            days++;
        }

        while(days >= 365) //not exactly accurate, but who the hell is gonna have a playtime of 1 year???
        {
            days -= 365;
            if(years < Utils.INT_MAX) years++; //stop so no overflow happens
        }
    }

    public function toString():String {
        var s:String = "";

        if(years > 0) s += years+" Years, ";
        if(days > 0) s += days+" Days, ";
        if(hours > 0) s += hours+" Hours, ";
        if(minutes > 0) s += minutes+" Minutes, ";
        s += seconds+" Seconds.";

        return s;
    }

}