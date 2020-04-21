# InterruptManager

A very simple addon that will let you set up interrupt rotations within a raid or a party. Will also announce when you use an interrupt for general use (can be disabled).

Usage: '/im', '/ima' or '/interruptmanager'

Simply fill in the names of the interrupters in the order you want them. If you do not have use for 5 interrupters, leave the boxes as they are or empty. More than 5 interrupts per rotation should never be needed. Click the numbered icons to the left of the editboxes to fill in the name of your target.

Note: All of the interrupting players should have the addon for optimal functionality. However, it is fine for you to set up rotations without everyone having the addon. In this case, you will announce whose turn it is in whichever channel you prefer.

Note 2: People running French clients will have to use '/ima' or '/interruptmanager' due to '/im' being reserved by the client.

Note 3: Due to how Blizzard chose to design the functionality of Warlock pet interrupts, the spell will sometimes be shown as being on cooldown when it's not. It's a straightforward job to implement a workaround however, will hopefully do it in the near future. If you're using Grimoire of Sacrifice, the spell will work like any other interrupt though.

Please comment, post bugs or suggestions at www.curse.com
# Features

    Bars display the cooldowns of players' interrupt abilities, as well as everyone's position in the rotation.
    Will warn you when it is your turn to interrupt next.
    Will warn you when your target/focus begins casting a spell while it is your turn to interrupt.
    Announces in /say when you use an interrupt ability (can be disabled).
    Dynamic rotation: places the player with the longest cooldown remaining on their interrupt spell last in the rotation.
    Availability check: Dead, disconnected or not present players will always be placed in the back of the rotation.

    Solo Mode: Enable to always be warned when your target begins casting a spell, even if you are not in the queue.
    PUG mode: Enable if not everyone has the addon installed. You will announce when someone interrupts, and whose turn it is to interrupt next spell.
    Multi-Rotation support: Different rotation setups within a raid will not interfere with each other.
    Target/focus support: Track the spellcasts of your target, focus or both.

# Todo:

    Bars should display other conditions that cause players to be unable to interrupt.

