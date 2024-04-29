// This file Copyright © 2009-2023 Mnemosyne LLC.
// It may be used under GPLv2 (SPDX: GPL-2.0-only), GPLv3 (SPDX: GPL-3.0-only),
// or any future license endorsed by Mnemosyne LLC.
// License text can be found in the licenses/ folder.

#pragma once

#include <libtransmission/tr-macros.h>

#include "BaseDialog.h"
#include "ui_LicenseDialog.h"

class LicenseDialog : public BaseDialog
{
    Q_OBJECT
    TR_DISABLE_COPY_MOVE(LicenseDialog)

public:
    explicit LicenseDialog(QWidget* parent = nullptr);

private:
    Ui::LicenseDialog ui_ = {};
};
