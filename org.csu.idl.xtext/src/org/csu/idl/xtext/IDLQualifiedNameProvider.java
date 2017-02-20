package org.csu.idl.xtext;

import org.csu.idl.idlmm.Contained;
import org.csu.idl.idlmm.Container;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider;
import org.eclipse.xtext.naming.QualifiedName;

public class IDLQualifiedNameProvider extends
		DefaultDeclarativeQualifiedNameProvider {
	
//	public QualifiedName qualifiedName(TranslationUnit g) {
//		return QualifiedName.create(g.getIdentifier());
//	}
//
	public QualifiedName qualifiedName(Contained item) {
		Container c = getContainer(item);
		QualifiedName qn = null;
		if (c==null)
			qn = QualifiedName.create(item.getIdentifier());
		else {
			QualifiedName qnCont = getFullyQualifiedName(c);
			qn = qnCont.append(item.getIdentifier());
		}
		return qn;
	}
	

	private Container getContainer(Contained item) {
		EObject i = item.eContainer();
		while (i!=null && !(i instanceof Container)) {
			i = i.eContainer();
		}
		return (Container)i;
	}
}