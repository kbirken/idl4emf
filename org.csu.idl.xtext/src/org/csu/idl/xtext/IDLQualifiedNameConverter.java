package org.csu.idl.xtext;

import org.eclipse.xtext.naming.IQualifiedNameConverter;

public class IDLQualifiedNameConverter extends IQualifiedNameConverter.DefaultImpl {

	@Override
	public String getDelimiter() {
		return "::";
	}

}
