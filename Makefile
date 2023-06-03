include $(TOPDIR)/rules.mk

PKG_NAME:=glinet-tac-fix
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/glinet-tac-fix
  SECTION:=base
  CATEGORY:=gl-inet
  TITLE:=GL iNet IMEI TAC of quectel modem fix tool
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)
endef

MAKE_FLAGS += \
		CFLAGS+="$(TARGET_CFLAGS) -Wall"


define Package/glinet-tac-fix/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/init.d/ $(1)/usr/share
	$(CP) ./files/special_imei.txt $(1)/usr/share
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sendat  $(1)/usr/bin
	$(INSTALL_BIN) ./files/imei_handle.sh  $(1)/usr/bin
	$(INSTALL_BIN) ./files/fix_tac.init $(1)/etc/init.d/fix_tac
endef

$(eval $(call BuildPackage,glinet-tac-fix))

