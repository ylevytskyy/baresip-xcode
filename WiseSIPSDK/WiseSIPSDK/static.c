/* static.c - manually updated */
#include <re_types.h>
#include <re_mod.h>

extern const struct mod_export exports_srtp;
extern const struct mod_export exports_selfview;
extern const struct mod_export exports_syslog;
extern const struct mod_export exports_coreaudio;
extern const struct mod_export exports_vidbridge;
extern const struct mod_export exports_presence;
extern const struct mod_export exports_natpmp;
extern const struct mod_export exports_mwi;
extern const struct mod_export exports_l16;
extern const struct mod_export exports_httpd;
extern const struct mod_export exports_fakevideo;
extern const struct mod_export exports_echo;
extern const struct mod_export exports_dtmfio;
extern const struct mod_export exports_dtls_srtp;
extern const struct mod_export exports_debug_cmd;
extern const struct mod_export exports_ctrl_tcp;
extern const struct mod_export exports_b2bua;
extern const struct mod_export exports_cons;
extern const struct mod_export exports_g711;
extern const struct mod_export exports_account;
extern const struct mod_export exports_contact;
extern const struct mod_export exports_menu;
extern const struct mod_export exports_auloop;
extern const struct mod_export exports_vidloop;
extern const struct mod_export exports_uuid;
extern const struct mod_export exports_stun;
extern const struct mod_export exports_turn;
extern const struct mod_export exports_ice;
extern const struct mod_export exports_vumeter;
extern const struct mod_export exports_audiounit;
extern const struct mod_export exports_amr;
extern const struct mod_export exports_aubridge;
extern const struct mod_export exports_aufile;
extern const struct mod_export exports_avcapture;

const struct mod_export *mod_table[] = {
    &exports_srtp,
    &exports_selfview,
    &exports_syslog,
    &exports_coreaudio,
    &exports_vidbridge,
    &exports_presence,
    &exports_natpmp,
    &exports_mwi,
    &exports_l16,
    &exports_httpd,
    &exports_fakevideo,
    &exports_echo,
    &exports_dtmfio,
    &exports_dtls_srtp,
    &exports_debug_cmd,
    &exports_ctrl_tcp,
    &exports_b2bua,
    &exports_cons,
    &exports_g711,
    &exports_account,
    &exports_contact,
    &exports_menu,
    &exports_auloop,
    &exports_vidloop,
    &exports_uuid,
    &exports_stun,
    &exports_turn,
    &exports_ice,
    &exports_vumeter,
    &exports_audiounit,
    &exports_amr,
    &exports_aubridge,
    &exports_aufile,
    &exports_avcapture,
    NULL
};
