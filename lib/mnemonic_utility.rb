# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

module MnemonicUtility


  def sort_by_mnemonic_month(list)
    months = {JAN: 1, FEB: 2, MAR: 3, APR: 4, MAY: 5, JUN: 6, JUL: 7, AUG: 8, SEP: 9, OCT: 10, NOV: 11, DEC: 12}
    list.sort do |x, y|
      x_month_sym = x.mnemonic[-3,3].to_sym
      y_month_sym = y.mnemonic[-3,3].to_sym
      x_month = months[x_month_sym]
      y_month = months[y_month_sym]
      x_month <=> y_month
    end
  end

end
