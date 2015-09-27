#!/usr/bin/env bash
# Zenburn - Gnome Terminal color scheme install script
# Alex Landovskis
# Based on a Bozhidar Batsov's port of Jani Nurminen's vim theme.

[[ -z "$PROFILE_NAME" ]] && PROFILE_NAME="Zenburn"
[[ -z "$PROFILE_SLUG" ]] && PROFILE_SLUG="zenburn"
[[ -z "$DCONF" ]] && DCONF=dconf
[[ -z "$UUIDGEN" ]] && UUIDGEN=uuidgen

# All Theme Colours
[[ -z "$ZENBURN_FG_LIGHTER_1" ]] && ZENBURN_FG_LIGHTER_1="#FFFFEF"
[[ -z "$ZENBURN_FG" ]] && ZENBURN_FG="#DCDCCC"
[[ -z "$ZENBURN_FG_DARKER_1" ]] && ZENBURN_FG_DARKER_1="#656555"
[[ -z "$ZENBURN_BG_DARKER_2" ]] && ZENBURN_BG_DARKER_2="#000000"
[[ -z "$ZENBURN_BG_DARKER_1" ]] && ZENBURN_BG_DARKER_1="#2B2B2B"
[[ -z "$ZENBURN_BG_DARKER_05" ]] && ZENBURN_BG_DARKER_05="#383838"
[[ -z "$ZENBURN_BG" ]] && ZENBURN_BG="#3F3F3F"
[[ -z "$ZENBURN_BG_LIGHTER_05" ]] && ZENBURN_BG_LIGHTER_05="#494949"
[[ -z "$ZENBURN_BG_LIGHTER_1" ]] && ZENBURN_BG_LIGHTER_1="#4F4F4F"
[[ -z "$ZENBURN_BG_LIGHTER_2" ]] && ZENBURN_BG_LIGHTER_2="#5F5F5F"
[[ -z "$ZENBURN_BG_LIGHTER_3" ]] && ZENBURN_BG_LIGHTER_3="#6F6F6F"
[[ -z "$ZENBURN_RED_LIGHTER_1" ]] && ZENBURN_RED_LIGHTER_1="#DCA3A3"
[[ -z "$ZENBURN_RED" ]] && ZENBURN_RED="#CC9393"
[[ -z "$ZENBURN_RED_DARKER_1" ]] && ZENBURN_RED_DARKER_1="#BC8383"
[[ -z "$ZENBURN_RED_DARKER_2" ]] && ZENBURN_RED_DARKER_2="#AC7373"
[[ -z "$ZENBURN_RED_DARKER_3" ]] && ZENBURN_RED_DARKER_3="#9C6363"
[[ -z "$ZENBURN_RED_DARKER_4" ]] && ZENBURN_RED_DARKER_4="#8C5353"
[[ -z "$ZENBURN_ORANGE" ]] && ZENBURN_ORANGE="#DFAF8F"
[[ -z "$ZENBURN_YELLOW" ]] && ZENBURN_YELLOW="#F0DFAF"
[[ -z "$ZENBURN_YELLOW_DARKER_1" ]] && ZENBURN_YELLOW_DARKER_1="#E0CF9F"
[[ -z "$ZENBURN_YELLOW_DARKER_2" ]] && ZENBURN_YELLOW_DARKER_2="#D0BF8F"
[[ -z "$ZENBURN_GREEN_DARKER_1" ]] && ZENBURN_GREEN_DARKER_1="#5F7F5F"
[[ -z "$ZENBURN_GREEN" ]] && ZENBURN_GREEN="#7F9F7F"
[[ -z "$ZENBURN_GREEN_LIGHTER_1" ]] && ZENBURN_GREEN_LIGHTER_1="#8FB28F"
[[ -z "$ZENBURN_GREEN_LIGHTER_2" ]] && ZENBURN_GREEN_LIGHTER_2="#9FC59F"
[[ -z "$ZENBURN_GREEN_LIGHTER_3" ]] && ZENBURN_GREEN_LIGHTER_3="#AFD8AF"
[[ -z "$ZENBURN_GREEN_LIGHTER_4" ]] && ZENBURN_GREEN_LIGHTER_4="#BFEBBF"
[[ -z "$ZENBURN_CYAN" ]] && ZENBURN_CYAN="#93E0E3"
[[ -z "$ZENBURN_BLUE_LIGHTER_1" ]] && ZENBURN_BLUE_LIGHTER_1="#94BFF3"
[[ -z "$ZENBURN_BLUE" ]] && ZENBURN_BLUE="#8CD0D3"
[[ -z "$ZENBURN_BLUE_DARKER_1" ]] && ZENBURN_BLUE_DARKER_1="#7CB8BB"
[[ -z "$ZENBURN_BLUE_DARKER_2" ]] && ZENBURN_BLUE_DARKER_2="#6CA0A3"
[[ -z "$ZENBURN_BLUE_DARKER_3" ]] && ZENBURN_BLUE_DARKER_3="#5C888B"
[[ -z "$ZENBURN_BLUE_DARKER_4" ]] && ZENBURN_BLUE_DARKER_4="#4C7073"
[[ -z "$ZENBURN_BLUE_DARKER_5" ]] && ZENBURN_BLUE_DARKER_5="#366060"
[[ -z "$ZENBURN_MAGENTA" ]] && ZENBURN_MAGENTA="#DC8CC3"

# Used Theme Colours
[[ -z "$__BG" ]] && __BG="${ZENBURN_BG}"
[[ -z "$__FG" ]] && __FG="${ZENBURN_FG}"
[[ -z "$__BLACK" ]] && __BLACK="${ZENBURN_BG}"
[[ -z "$__BLACK_LIGHT" ]] && __BLACK_LIGHT="${ZENBURN_BG_LIGHTER_1}"
[[ -z "$__RED" ]] && __RED="${ZENBURN_RED}"
[[ -z "$__RED_LIGHT" ]] && __RED_LIGHT="${ZENBURN_RED_LIGHTER_1}"
[[ -z "$__GREEN" ]] && __GREEN="${ZENBURN_GREEN}"
[[ -z "$__GREEN_LIGHT" ]] && __GREEN_LIGHT="${ZENBURN_GREEN_LIGHTER_1}"
[[ -z "$__YELLOW" ]] && __YELLOW="${ZENBURN_YELLOW_DARKER_1}"
[[ -z "$__YELLOW_LIGHT" ]] && __YELLOW_LIGHT="${ZENBURN_YELLOW}"
[[ -z "$__BLUE" ]] && __BLUE="${ZENBURN_BLUE}"
[[ -z "$__BLUE_LIGHT" ]] && __BLUE_LIGHT="${ZENBURN_BLUE_LIGHTER_1}"
[[ -z "$__MAGENTA" ]] && __MAGENTA="${ZENBURN_MAGENTA}"
[[ -z "$__MAGENTA_LIGHT" ]] && __MAGENTA_LIGHT="${ZENBURN_MAGENTA}"
[[ -z "$__CYAN" ]] && __CYAN="${ZENBURN_CYAN}"
[[ -z "$__CYAN_LIGHT" ]] && __CYAN_LIGHT="${ZENBURN_CYAN}"
[[ -z "$__WHITE" ]] && __WHITE="${ZENBURN_FG}"
[[ -z "$__WHITE_LIGHT" ]] && __WHITE_LIGHT="${ZENBURN_FG_LIGHTER_1}"

dset() {
    local key="$1"; shift
    local val="$1"; shift

    if [[ "$type" == "string" ]]; then
        val="'$val'"
    fi

    "$DCONF" write "$PROFILE_KEY/$key" "$val"
}

# because dconf still doesn't have "append"
dlist_append() {
    local key="$1"; shift
    local val="$1"; shift

    local entries="$(
        {
            "$DCONF" read "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
            echo "'$val'"
        } | head -c-1 | tr "\n" ,
    )"

    "$DCONF" write "$key" "[$entries]"
}

# Newest versions of gnome-terminal use dconf
if which "$DCONF" > /dev/null 2>&1; then
    [[ -z "$BASE_KEY_NEW" ]] && BASE_KEY_NEW=/org/gnome/terminal/legacy/profiles:

    if [[ -n "`$DCONF list $BASE_KEY_NEW/`" ]]; then
        if which "$UUIDGEN" > /dev/null 2>&1; then
            PROFILE_SLUG=`uuidgen`
        fi

        if [[ -n "`$DCONF read $BASE_KEY_NEW/default`" ]]; then
            DEFAULT_SLUG=`$DCONF read $BASE_KEY_NEW/default | tr -d \'`
        else
            DEFAULT_SLUG=`$DCONF list $BASE_KEY_NEW/ | grep '^:' | head -n1 | tr -d :/`
        fi

        DEFAULT_KEY="$BASE_KEY_NEW/:$DEFAULT_SLUG"
        PROFILE_KEY="$BASE_KEY_NEW/:$PROFILE_SLUG"

        # copy existing settings from default profile
        $DCONF dump "$DEFAULT_KEY/" | $DCONF load "$PROFILE_KEY/"

        # add new copy to list of profiles
        dlist_append $BASE_KEY_NEW/list "$PROFILE_SLUG"

        PALETTE="['${__BLACK}', '${__RED}', '${__GREEN}', '${__YELLOW}', '${__BLUE}', '${__MAGENTA}', '${__CYAN}', '${__WHITE}'"
        PALETTE="${PALETTE}, '${__BLACK_LIGHT}', '${__RED_LIGHT}', '${__GREEN_LIGHT}', '${__YELLOW_LIGHT}', '${__BLUE_LIGHT}', '${__MAGENTA_LIGHT}', '${__CYAN_LIGHT}', '${__WHITE_LIGHT}']"

        # update profile values with theme options
        dset visible-name "'$PROFILE_NAME'"
        dset palette ${PALETTE}
        dset background-color "'${__BG}'"
        dset foreground-color "'${__FG}'"
        dset bold-color "'${__FG}'"
        dset bold-color-same-as-fg "true"
        dset use-theme-colors "false"
        dset use-theme-background "false"

        unset PROFILE_NAME
        unset PROFILE_SLUG
        unset DCONF
        unset UUIDGEN
        exit 0
    fi
fi

# Fallback for Gnome 2 and early Gnome 3
[[ -z "$GCONFTOOL" ]] && GCONFTOOL=gconftool-2
[[ -z "$BASE_KEY" ]] && BASE_KEY=/apps/gnome-terminal/profiles

PROFILE_KEY="$BASE_KEY/$PROFILE_SLUG"

gset() {
    local type="$1"; shift
    local key="$1"; shift
    local val="$1"; shift

    "$GCONFTOOL" --set --type "$type" "$PROFILE_KEY/$key" -- "$val"
}

# Because gconftool doesn't have "append"
glist_append() {
    local type="$1"; shift
    local key="$1"; shift
    local val="$1"; shift

    local entries="$(
        {
            "$GCONFTOOL" --get "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
            echo "$val"
        } | head -c-1 | tr "\n" ,
    )"

    "$GCONFTOOL" --set --type list --list-type $type "$key" "[$entries]"
}

# Append the Base16 profile to the profile list
glist_append string /apps/gnome-terminal/global/profile_list "$PROFILE_SLUG"

PALETTE="${__BLACK}:${__RED}:${__GREEN}:${__YELLOW}:${__BLUE}:${__MAGENTA}:${__CYAN}:${__WHITE}"
PALETTE="${PALETTE}:${__BLACK_LIGHT}:${__RED_LIGHT}:${__GREEN_LIGHT}:${__YELLOW_LIGHT}:${__BLUE_LIGHT}:${__MAGENTA_LIGHT}:${__CYAN_LIGHT}:${__WHITE_LIGHT}"

gset string visible_name "$PROFILE_NAME"
gset string palette ${PALETTE}
gset string background_color "${__BG}"
gset string foreground_color "${__FG}"
gset string bold_color "${__FG}"
gset bool   bold_color_same_as_fg "true"
gset bool   use_theme_colors "false"
gset bool   use_theme_background "false"

unset PROFILE_NAME
unset PROFILE_SLUG
unset DCONF
unset UUIDGEN

unset ZENBURN_FG_LIGHTER_1
unset ZENBURN_FG
unset ZENBURN_FG_DARKER_1
unset ZENBURN_BG_DARKER_2
unset ZENBURN_BG_DARKER_1
unset ZENBURN_BG_DARKER_05
unset ZENBURN_BG
unset ZENBURN_BG_LIGHTER_05
unset ZENBURN_BG_LIGHTER_1
unset ZENBURN_BG_LIGHTER_2
unset ZENBURN_BG_LIGHTER_3
unset ZENBURN_RED_LIGHTER_1
unset ZENBURN_RED
unset ZENBURN_RED_DARKER_1
unset ZENBURN_RED_DARKER_2
unset ZENBURN_RED_DARKER_3
unset ZENBURN_RED_DARKER_4
unset ZENBURN_ORANGE
unset ZENBURN_YELLOW
unset ZENBURN_YELLOW_DARKER_1
unset ZENBURN_YELLOW_DARKER_2
unset ZENBURN_GREEN_DARKER_1
unset ZENBURN_GREEN
unset ZENBURN_GREEN_LIGHTER_1
unset ZENBURN_GREEN_LIGHTER_2
unset ZENBURN_GREEN_LIGHTER_3
unset ZENBURN_GREEN_LIGHTER_4
unset ZENBURN_CYAN
unset ZENBURN_BLUE_LIGHTER_1
unset ZENBURN_BLUE
unset ZENBURN_BLUE_DARKER_1
unset ZENBURN_BLUE_DARKER_2
unset ZENBURN_BLUE_DARKER_3
unset ZENBURN_BLUE_DARKER_4
unset ZENBURN_BLUE_DARKER_5
unset ZENBURN_MAGENTA
unset __BG
unset __FG
unset __BLACK
unset __BLACK_LIGHT
unset __RED
unset __RED_LIGHT
unset __GREEN
unset __GREEN_LIGHT
unset __YELLOW
unset __YELLOW_LIGHT
unset __BLUE
unset __BLUE_LIGHT
unset __MAGENTA
unset __MAGENTA_LIGHT
unset __CYAN
unset __CYAN_LIGHT
unset __WHITE
unset __WHITE_LIGHT
